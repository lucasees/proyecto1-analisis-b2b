"""
Proyecto 1 — Runner reproducible (SQLite en memoria).
Carga los 5 CSV, ejecuta las queries RFM (04) y cohortes (05) sobre los datos
reales, imprime los resultados y exporta CSVs listos para Power BI en /salidas.
Uso:  python3 run_analisis.py
"""
import sqlite3
from pathlib import Path
import pandas as pd

BASE = Path(__file__).resolve().parent.parent
DATOS = BASE / "datos"
SQL = BASE / "sql"
SALIDAS = BASE / "salidas"
SALIDAS.mkdir(exist_ok=True)

con = sqlite3.connect(":memory:")
for t in ["clientes", "productos", "pedidos", "detalle_pedidos", "prospectos"]:
    pd.read_csv(DATOS / f"{t}.csv").to_sql(t, con, index=False, if_exists="replace")

rfm = pd.read_sql_query((SQL / "04_rfm_segmentacion.sql").read_text(), con)
coh = pd.read_sql_query((SQL / "05_cohortes_retencion.sql").read_text(), con)

# ── RFM ────────────────────────────────────────────────────────────────────
print("=" * 60)
print("SEGMENTACIÓN RFM — distribución de clientes por segmento")
print("=" * 60)
dist = (rfm.groupby("segmento_rfm")
           .agg(clientes=("cliente_id", "count"),
                facturacion=("monetary", "sum"))
           .sort_values("facturacion", ascending=False))
dist["% facturación"] = (dist["facturacion"] / dist["facturacion"].sum() * 100).round(1)
print(dist.to_string())
print(f"\nTotal clientes segmentados: {len(rfm)}  |  "
      f"Facturación total: ${rfm['monetary'].sum():,.0f}")

print("\nTop 5 Campeones (mayor Monetary):")
print(rfm[rfm.segmento_rfm == "Campeones"]
      .nlargest(5, "monetary")[["nombre_empresa", "recency_dias",
                                "frequency", "monetary", "celda_rfm"]]
      .to_string(index=False))

# ── Cohortes ────────────────────────────────────────────────────────────────
print("\n" + "=" * 60)
print("COHORTES — matriz de retención trimestral (% de la cohorte activa)")
print("=" * 60)
pivot = coh.pivot(index="cohorte", columns="offset_trim", values="retencion_pct")
print(pivot.fillna("").to_string())

# ── Export para Power BI ────────────────────────────────────────────────────
rfm.to_csv(SALIDAS / "rfm_resultado.csv", index=False)
coh.to_csv(SALIDAS / "cohortes_resultado.csv", index=False)
print(f"\n✅ Exportado a {SALIDAS}/  (rfm_resultado.csv, cohortes_resultado.csv)")
con.close()
