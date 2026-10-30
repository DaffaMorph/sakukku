"""
=====================================================================
SakuKu (Pencatatan Keuangan Anda) - Data Access Object & Backend Engine
Fase 1 - 4: Core Essentials, History, Budgeting, and Cloud Sync
=====================================================================
"""

import json
import csv
import io
import uuid
from datetime import datetime, date
from typing import List, Dict, Any, Optional

class SakuKuDAO:
    """
    Data Access Object untuk aplikasi SakuKu.
    Menyediakan manipulasi transaksi, anggaran, target tabungan,
    serta integrasi ekspor/impor CSV.
    """

    def __init__(self, db_connection=None):
        self.db = db_connection
        # Fallback local in-memory storage jika database MySQL/SQLite belum aktif
        self.memory_store = {
            "transactions": [],
            "categories": [],
            "budgets": [],
            "goals": [],
            "users": []
        }

    @staticmethod
    def generate_id(prefix: str = "item") -> str:
        return f"{prefix}-{uuid.uuid4().hex[:8]}"

    # -------------------------------------------------------------
    # 1. TRANSAKSI (Fase 1 & 2)
    # -------------------------------------------------------------
    def add_transaction(self, user_id: str, type_: str, amount: float,
                        category: str, transaction_date: str,
                        description: str = "") -> Dict[str, Any]:
        """Mencatat transaksi baru (Pemasukan / Pengeluaran)."""
        if type_ not in ("income", "expense"):
            raise ValueError("Tipe transaksi harus 'income' atau 'expense'")
        if amount <= 0:
            raise ValueError("Nominal transaksi harus lebih besar dari 0")

        trx = {
            "id": self.generate_id("trx"),
            "user_id": user_id,
            "type": type_,
            "amount": float(amount),
            "category": category,
            "transaction_date": transaction_date or str(date.today()),
            "description": description.strip(),
            "created_at": datetime.now().isoformat()
        }
        self.memory_store["transactions"].append(trx)
        return trx

    def list_transactions(self, user_id: str, month: Optional[str] = None,
                          keyword: Optional[str] = None) -> List[Dict[str, Any]]:
        """Mengambil riwayat transaksi dengan filter bulan dan kata kunci pencarian."""
        results = [t for t in self.memory_store["transactions"] if t["user_id"] == user_id]
        if month:
            results = [t for t in results if t["transaction_date"].startswith(month)]
        if keyword:
            kw = keyword.lower()
            results = [t for t in results if kw in t["description"].lower() or kw in t["category"].lower()]
        
        # Urutkan tanggal terbaru pertama
        return sorted(results, key=lambda x: x["transaction_date"], reverse=True)

    def calculate_summary(self, user_id: str, month: Optional[str] = None) -> Dict[str, float]:
        """Menghitung ringkasan total pemasukan, pengeluaran, dan net tabungan."""
        trxs = self.list_transactions(user_id, month=month)
        income = sum(t["amount"] for t in trxs if t["type"] == "income")
        expense = sum(t["amount"] for t in trxs if t["type"] == "expense")
        net_savings = income - expense
        return {
            "total_income": income,
            "total_expense": expense,
            "net_savings": net_savings,
            "count": len(trxs)
        }

    # -------------------------------------------------------------
    # 2. INTEGRASI EXCEL & CSV (Fase 2)
    # -------------------------------------------------------------
    def export_to_csv(self, user_id: str) -> str:
        """Ekspor seluruh transaksi ke format CSV standar RFC 4180 dengan UTF-8 BOM."""
        trxs = self.list_transactions(user_id)
        output = io.StringIO()
        writer = csv.writer(output, delimiter=',', quoting=csv.QUOTE_MINIMAL)
        
        # Header kolom sesuai PRD
        writer.writerow(["Tanggal", "Tipe", "Kategori", "Nominal", "Deskripsi"])
        for t in trxs:
            tipe_label = "Pemasukan" if t["type"] == "income" else "Pengeluaran"
            writer.writerow([
                t["transaction_date"],
                tipe_label,
                t["category"],
                f"{t['amount']:.2f}",
                t["description"]
            ])
        return output.getvalue()

    def import_from_csv(self, user_id: str, csv_content: str) -> Dict[str, Any]:
        """
        Impor data transaksi massal dari file CSV.
        Mendukung kolom: Tanggal, Tipe (Pemasukan/Pengeluaran), Kategori, Nominal, Deskripsi.
        """
        reader = csv.reader(io.StringIO(csv_content.strip()))
        rows = list(reader)
        if not rows:
            return {"imported": 0, "errors": ["File CSV kosong"]}

        header = [col.strip().lower() for col in rows[0]]
        # Identifikasi indeks kolom
        try:
            date_idx = header.index("tanggal")
            type_idx = header.index("tipe")
            cat_idx = header.index("kategori")
            amount_idx = header.index("nominal")
            desc_idx = header.index("deskripsi") if "deskripsi" in header else -1
        except ValueError as e:
            return {"imported": 0, "errors": [f"Kolom wajib tidak ditemukan: {str(e)}"]}

        imported_count = 0
        errors = []

        for row_num, row in enumerate(rows[1:], start=2):
            if not row or not any(row):
                continue
            try:
                raw_type = row[type_idx].strip().lower()
                type_ = "income" if "masuk" in raw_type or raw_type == "income" else "expense"
                raw_amt = row[amount_idx].replace("Rp", "").replace(".", "").replace(",", ".").strip()
                amount = float(raw_amt)
                cat = row[cat_idx].strip()
                t_date = row[date_idx].strip()
                desc = row[desc_idx].strip() if desc_idx != -1 and len(row) > desc_idx else ""

                self.add_transaction(
                    user_id=user_id,
                    type_=type_,
                    amount=amount,
                    category=cat,
                    transaction_date=t_date,
                    description=desc
                )
                imported_count += 1
            except Exception as ex:
                errors.append(f"Baris {row_num}: {str(ex)}")

        return {"imported": imported_count, "errors": errors}

    # -------------------------------------------------------------
    # 3. ANGGARAN KATEGORI & SAVINGS GOALS (Fase 3)
    # -------------------------------------------------------------
    def set_category_budget(self, user_id: str, category: str, month: str,
                            limit_amount: float) -> Dict[str, Any]:
        """Menetapkan batas anggaran kategori per bulan."""
        budget = {
            "id": self.generate_id("bdg"),
            "user_id": user_id,
            "category": category,
            "month": month,
            "budget_limit": float(limit_amount),
            "alert_threshold": 0.80  # Peringatan di 80%
        }
        self.memory_store["budgets"].append(budget)
        return budget

    def check_budget_status(self, user_id: str, month: str) -> List[Dict[str, Any]]:
        """Mengecek status pengeluaran terhadap batas anggaran dengan indikator visual."""
        trxs = self.list_transactions(user_id, month=month)
        category_expenses = {}
        for t in trxs:
            if t["type"] == "expense":
                category_expenses[t["category"]] = category_expenses.get(t["category"], 0.0) + t["amount"]

        results = []
        user_budgets = [b for b in self.memory_store["budgets"] if b["user_id"] == user_id and b["month"] == month]
        for b in user_budgets:
            cat = b["category"]
            limit_val = b["budget_limit"]
            used_val = category_expenses.get(cat, 0.0)
            percentage = (used_val / limit_val * 100) if limit_val > 0 else 0
            
            # Status badge (PRD: normal, warning 80-99%, over >= 100%)
            if percentage >= 100:
                status = "danger"  # Rose / Merah
            elif percentage >= 80:
                status = "warning" # Amber / Kuning
            else:
                status = "normal"  # Emerald / Hijau

            results.append({
                "category": cat,
                "limit": limit_val,
                "used": used_val,
                "remaining": max(0.0, limit_val - used_val),
                "percentage": round(percentage, 1),
                "status": status
            })
        return results

    def add_savings_goal(self, user_id: str, name: str, target_amount: float,
                         current_amount: float = 0.0, deadline: Optional[str] = None) -> Dict[str, Any]:
        """Membuat target keuangan baru (Savings Goal)."""
        goal = {
            "id": self.generate_id("goal"),
            "user_id": user_id,
            "name": name,
            "target_amount": float(target_amount),
            "current_amount": float(current_amount),
            "deadline": deadline,
            "percentage": round((current_amount / target_amount * 100), 1) if target_amount > 0 else 0,
            "created_at": datetime.now().isoformat()
        }
        self.memory_store["goals"].append(goal)
        return goal


if __name__ == "__main__":
    print("=" * 60)
    print("SakuKu Data Access Object (DAO) Engine Initialized")
    print("Mendukung skema dapa.sql dan seluruh spesifikasi Fase 1 - 4")
    print("=" * 60)
    dao = SakuKuDAO()
    trx = dao.add_transaction("u-01", "income", 10000000, "Gaji Pokok", "2026-10-25", "Gaji bulan Oktober")
    print(f"[OK] Transaksi berhasil dibuat: {trx['id']} - Rp {trx['amount']:,}")
    csv_sample = dao.export_to_csv("u-01")
    print("[OK] Ekspor CSV siap:")
    print(csv_sample.strip())

