import findspark
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
findspark.init()
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, trim, lower
from pyspark.sql import functions as F


# =================================
# Conversión de archivos
# =================================

# Convertir archivo de OIJ
def convertOIJ():
    df = pd.read_html("C:/proyectoIII/data/oij.xls")[0]
    df.to_excel("C:/proyectoIII/data/oijConv.xlsx", index=False)

# Convertir archivo de INEC
def convertINEC():
    dfRaw = pd.read_excel("C:/proyectoIII/data/inec.xls", header=None)
    dfRaw.to_excel("C:/proyectoIII/data/inecConv.xlsx", index=False)
    
    # Eliminar espacios en blanco
    df = pd.read_excel("C:/proyectoIII/data/inecConv.xlsx", header=None)
    df = df.drop(columns=[df.columns[0]])

    mask = df.eq("Provincia, cantón y distrito")
    headerRow = mask[mask.any(axis=1)].index[0]

    df.columns = df.iloc[headerRow]
    df.columns = [c.strip() if isinstance(c, str) else c for c in df.columns]

    df = df[headerRow+1:].reset_index(drop=True)
    col = "Provincia, cantón y distrito"
    df = df[df[col].notna()].copy()

    df = df.dropna(how="all")
    cols = list(df.columns)
    idx = cols.index("Porcentaje de población ocupada")

    cols[idx] = "Porcentaje de población ocupada: Sector primario"
    cols[idx+1] = "Porcentaje de población ocupada: Sector secundario"
    cols[idx+2] = "Porcentaje de población ocupada: Sector terciario"
    df.columns = cols

    # Separar provincia, cantón y distrito
    nameCol = "Provincia, cantón y distrito"
    popCol = df.columns[df.columns.get_loc(nameCol)+1]

    df = df.reset_index(drop=True)
    countryVals = []
    provVals = []
    cantonVals = []
    distritoVals = []

    countryName = df.loc[0, nameCol]
    countryAcc = 0.0
    prov = None
    provTarget = 0.0
    provAcc = 0.0
    canton = None
    cantonTarget = 0.0
    cantonAcc = 0.0

    TOL = 0.5

    for i, row in df.iterrows():
        name = row[nameCol]
        pop = row[popCol]

        try:
            val = float(pop)
        except (TypeError, ValueError):
            val = 0.0

        if i == 0:
            countryVals.append(countryName)
            provVals.append(np.nan)
            cantonVals.append(np.nan)
            distritoVals.append(np.nan)
            continue

        if prov is None:
            prov = name
            provTarget = val
            provAcc = 0.0
            canton = None
            cantonTarget = 0.0
            cantonAcc = 0.0
            countryVals.append(countryName)
            provVals.append(prov)
            cantonVals.append(np.nan)
            distritoVals.append(np.nan)
            continue

        if canton is None:
            canton = name
            cantonTarget = val
            cantonAcc = 0.0
            countryVals.append(countryName)
            provVals.append(prov)
            cantonVals.append(canton)
            distritoVals.append(np.nan)
            continue

        cantonAcc += val
        provAcc += val
        countryAcc += val

        countryVals.append(countryName)
        provVals.append(prov)
        cantonVals.append(canton)
        distritoVals.append(name)

        if abs(cantonAcc - cantonTarget) <= TOL:
            canton = None
            cantonTarget = 0.0
            cantonAcc = 0.0

        if abs(provAcc - provTarget) <= TOL:
            prov = None
            provTarget = 0.0
            provAcc = 0.0

    df["País"] = countryVals
    df["Provincia"] = provVals
    df["Cantón"] = cantonVals
    df["Distrito"] = distritoVals

    df = df.drop(columns=[nameCol])

    hierarchyCols = ["País", "Provincia", "Cantón", "Distrito"]
    rest = [c for c in df.columns if c not in hierarchyCols]
    df = df[hierarchyCols + rest]
    df.to_excel("C:/proyectoIII/data/inecConv.xlsx", index=False)


# =================================
# Configuración de Spark
# =================================

# Crear la sesión de Spark
spark = (SparkSession.builder
    .appName("ProyectoIII_SparkSQL")
    .config("spark.local.dir", "C:\\spark-temp")
    .config("spark.pyspark.python", sys.executable)
    .config("spark.pyspark.driver.python", sys.executable)
    .config("spark.jars.packages", "org.postgresql:postgresql:42.7.7")
    .getOrCreate()
    )
spark

# Cargar datos del OIJ
dfOIJ = spark.read.format("com.crealytics.spark.excel") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("treatEmptyValuesAsNulls", "true") \
    .option("addColorColumns", "false") \
    .option("workbookPassword", None) \
    .load("C:/proyectoIII/data/oijConv.xlsx")

# Cargar datos del INEC
dfINEC = spark.read.format("com.crealytics.spark.excel") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("treatEmptyValuesAsNulls", "true") \
    .option("addColorColumns", "false") \
    .option("workbookPassword", None) \
    .load("C:/proyectoIII/data/inecConv.xlsx")
 
# Conexión a la base de datos PostgreSQL
jdbc_url = "jdbc:postgresql://localhost:5432/proyecto3"
connection_props = {
    "user": "postgres",
    "password": "123",
    "driver": "org.postgresql.Driver"
}

# Cargar datos desde las tablas
dfOIJ_DB = spark.read.jdbc(
    url=jdbc_url,
    table="oij",
    properties=connection_props
)
dfINEC_DB = spark.read.jdbc(
    url=jdbc_url,
    table="inec",
    properties=connection_props
)


# =================================
# Creación de funciones
# =================================

# 1. Función para eliminar espacios
def normalizeText(df, column):
    return df.withColumn(column, trim(col(column)))

# 2. Función para convertir a minúsculas
def toLowerCase(df, column):
    return df.withColumn(column, lower(col(column)))

# 3. Función para encontrar distritos no coincidentes
def notMatchingDistricts(dfOIJ, dfINEC):
    distriOIJ = dfOIJ.select("Distrito").distinct()
    distriINEC = dfINEC.select("Distrito").distinct()
    notMatching = distriOIJ.subtract(distriINEC)
    return notMatching

# 4. Función para contar registros sin distrito coincidente
def sizeNotMatching(notMatching):
    return notMatching.count()

# 5. Función para converir nombres de distritos
def fixDistrictNames(dfOIJ, dfINEC, spark):
    dfOIJ = removeAccents(dfOIJ, ['Distrito', 'Provincia', 'Canton'])
    dfINEC = removeAccents(dfINEC, ['Distrito', 'Provincia', 'Cantón'])

    dfOIJ.createOrReplaceTempView("oij")
    dfINEC.createOrReplaceTempView("inec")

    spark.sql("""
        CREATE OR REPLACE TEMP VIEW oij_norm AS
        SELECT Distrito,
               lower(regexp_replace(Distrito, '^(la|los|las|el) ', '')) AS Distrito_norm,
               lower(`Provincia` || ' ' || `Canton`) AS ProvCanton_norm
        FROM oij
        WHERE Distrito IS NOT NULL AND TRIM(Distrito) <> ''
    """)

    spark.sql("""
        CREATE OR REPLACE TEMP VIEW inec_norm AS
        SELECT Distrito,
               lower(regexp_replace(Distrito, '^(la|los|las|el) ', '')) AS Distrito_norm,
               lower(`Provincia` || ' ' || `Cantón`) AS ProvCanton_norm
        FROM inec
        WHERE Distrito IS NOT NULL AND TRIM(Distrito) <> ''
    """)

    spark.sql("""
        CREATE OR REPLACE TEMP VIEW missing AS
        SELECT i.Distrito AS Distrito_INEC,
               i.Distrito_norm AS Distrito_norm_INEC,
               i.ProvCanton_norm AS ProvCanton_INEC
        FROM inec_norm i
        WHERE i.Distrito NOT IN (SELECT Distrito FROM oij_norm)
    """)

    spark.sql("""
        CREATE OR REPLACE TEMP VIEW levenshtein_pairs AS
        SELECT 
            m.Distrito_INEC,
            o.Distrito AS Distrito_OIJ,
            levenshtein(
                m.Distrito_norm_INEC || ' ' || m.ProvCanton_INEC,
                o.Distrito_norm || ' ' || o.ProvCanton_norm
            ) AS distance
        FROM missing m
        CROSS JOIN oij_norm o
    """)

    spark.sql("""
        CREATE OR REPLACE TEMP VIEW mapping AS
        SELECT Distrito_INEC, Distrito_OIJ
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY Distrito_INEC
                       ORDER BY distance ASC
                   ) AS rn
            FROM levenshtein_pairs
        ) t
        WHERE rn = 1
    """)

    cols = [c for c in dfINEC.columns if c != "Distrito"]
    cols_expr = ", ".join([f"i.`{c}`" for c in cols])

    spark.sql(f"""
        CREATE OR REPLACE TEMP VIEW inec_fixed AS
        SELECT COALESCE(m.Distrito_OIJ, i.Distrito) AS Distrito, {cols_expr}
        FROM inec i
        LEFT JOIN mapping m ON i.Distrito = m.Distrito_INEC
    """)

    cols_expr = ", ".join([f"x.`{c}`" for c in cols])

    spark.sql(f"""
        CREATE OR REPLACE TEMP VIEW inec_fixed2 AS
        SELECT 
            CASE
                WHEN lower(trim(x.Distrito)) = 'angeles'
                    AND lower(trim(x.Provincia)) = 'heredia'
                    AND lower(trim(x.`Cantón`)) = 'san rafael'
                THEN 'los angeles'

                WHEN lower(trim(x.Distrito)) = 'mercedes'
                    AND lower(trim(x.Provincia)) = 'limon'
                    AND lower(trim(x.`Cantón`)) = 'guacimo'
                THEN 'merecedes'

                ELSE x.Distrito
            END AS Distrito,
            {cols_expr}
        FROM inec_fixed x
    """)

    dfINEC_final = spark.table("inec_fixed2").drop("Distrito_1")
    return dfINEC_final

def removeAccents(df, cols):
    accents = "áéíóúüñÁÉÍÓÚÜÑ"
    replacements = "aeiouunAEIOUUN"
    for c in cols:
        df = df.withColumn(c, F.translate(F.col(c), accents, replacements))
    return df


# =================================
# Ejecución de funciones
# =================================

# Convertir archivos
convertOIJ()
convertINEC()

# Normalizar OIJ
dfOIJ = normalizeText(dfOIJ, "Distrito")
dfOIJ = toLowerCase(dfOIJ, "Distrito")

# Normalizar INEC
dfINEC = normalizeText(dfINEC, "Distrito")
dfINEC = toLowerCase(dfINEC, "Distrito")

# Encontrar distritos no coincidentes
notMatching = notMatchingDistricts(dfOIJ, dfINEC)
notMatching.show(200)

# Contar registros sin distrito coincidente
size = sizeNotMatching(notMatching)

# Arreglar nombres de distritos en INEC
dfINECFixed = fixDistrictNames(dfOIJ, dfINEC, spark)
dfINECFixed = dfINECFixed.select(dfINEC.columns)
dfINECFixed.toPandas().to_excel("C:/proyectoIII/data/inecFixed.xlsx", index=False)

# Guardar datos en la base de datos
dfOIJ.write.mode("overwrite").jdbc(url=jdbc_url, table="oij", properties=connection_props)
dfINECFixed.write.mode("overwrite").jdbc(url=jdbc_url, table="inec", properties=connection_props)


# =================================
#  Visualización de Datos
# =================================

# Vista 1
def graficarVista1(topN=10):
    View1_Distri = dfOIJ_DB.groupBy("Distrito").count().orderBy(F.desc("count")).limit(topN)
    View1_TasaAvg = dfINEC_DB.groupBy("Distrito").agg(F.avg(F.col("Tasa de ocupación")).alias("tasa_ocupacion"))
    View1 = View1_Distri.join(View1_TasaAvg, on="Distrito", how="left").toPandas()
    
    fig, ax1 = plt.subplots(figsize=(12,6))
    x = np.arange(len(View1))
    bars = ax1.bar(x, View1["count"], color="#186094", alpha=0.8)
    ax1.set_xticks(x)
    ax1.set_xticklabels(View1["Distrito"], rotation=45, ha="right")
    ax1.set_ylabel("Cantidad de delitos")
    
    for bar in bars:
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height(), str(int(bar.get_height())), ha='center', va='bottom')
    
    ax2 = ax1.twinx()
    ax2.plot(x, View1["tasa_ocupacion"], color="#ff160e", marker="o", linewidth=2)
    ax2.set_ylabel("Tasa de ocupación (%)")
    
    plt.title(f"Top {topN} Distritos con más Delitos vs Tasa de Ocupación")
    plt.tight_layout()
    plt.show()


# Vista 2
def graficarVista2():
    View2_DistriTop = dfOIJ_DB.groupBy("Distrito").count().orderBy(F.desc("count")).first()["Distrito"]
    orderDays = {"Mon":1, "Tue":2, "Wed":3, "Thu":4, "Fri":5, "Sat":6, "Sun":7}
    orderDaysES = {"Mon":"Lun", "Tue":"Mar", "Wed":"Mie", "Thu":"Jue", "Fri":"Vie", "Sat":"Sab", "Sun":"Dom"}

    View2_DelitoDay = (
        dfOIJ_DB
        .withColumn("FechaDT", F.to_date("Fecha", "yyyy-MM-dd"))
        .filter(F.col("Distrito") == View2_DistriTop)
        .withColumn("Dia_semana", F.date_format("FechaDT", "E"))
        .withColumn("Dia_num", F.udf(lambda x: orderDays[x], "int")(F.col("Dia_semana")))
        .groupBy("Dia_semana", "Dia_num")
        .count()
        .orderBy("Dia_num")
    )

    View2 = View2_DelitoDay.toPandas()
    View2["Dia_semana"] = View2["Dia_semana"].map(orderDaysES)

    plt.figure(figsize=(10,5))
    bars = plt.bar(View2["Dia_semana"], View2["count"], color="#3ccc41", alpha=0.7)

    for bar in bars:
        plt.text(bar.get_x() + bar.get_width()/2, bar.get_height(), str(int(bar.get_height())), ha='center', va='bottom')

    plt.xlabel("Día de la semana")
    plt.ylabel("Cantidad de delitos")
    plt.title(f"Cantidad de delitos por día de la semana - {View2_DistriTop}")
    plt.show()


# Vista 3
def graficarVista3(distrito):
    View3_DelitoType = dfOIJ_DB.filter(F.col("Distrito") == distrito).groupBy("Delito").count().orderBy(F.desc("count"))

    if View3_DelitoType.count() == 0:
        print(f"Nombre incorrecto o no existen datos para el distrito '{distrito}'.")
        return
    
    View3 = View3_DelitoType.toPandas()

    plt.figure(figsize=(12,6))
    colors = plt.cm.Dark2.colors
    wedges, texts, autotexts = plt.pie(View3["count"], labels=None, autopct="%1.1f%%", startangle=140, colors=colors[:len(View3)])
    plt.legend(wedges, View3["Delito"], title="Delitos", bbox_to_anchor=(1, 0.5), loc="center left")
    plt.title(f"Distribución de delitos por tipo - {distrito}")
    plt.tight_layout()
    plt.show()


# Vista 4
def graficarVista4():
    View4_DelitoGen = dfOIJ_DB.groupBy("Sexo").count().orderBy(F.desc("count"))
    View4 = View4_DelitoGen.toPandas()

    colors = plt.cm.tab10.colors
    plt.figure(figsize=(8,5))
    wedges, texts, autotexts = plt.pie(View4["count"], labels=None, autopct="%1.1f%%", startangle=90, colors=colors[:len(View4)])
    plt.legend(wedges, View4["Sexo"], title="Sexo", bbox_to_anchor=(1, 0.5), loc="center left")
    plt.title("Cantidad de delitos por sexo - Todo el conjunto de datos")
    plt.tight_layout()
    plt.show()


# Vista 5
def graficarVista5():
    View5_DelitoHour = dfOIJ_DB.withColumn("Hora_inicio", F.substring(F.col("Hora"), 1, 2).cast("int"))
    View5_Delitos = View5_DelitoHour.groupBy("Hora_inicio").count().orderBy("Hora_inicio")
    View5 = View5_Delitos.toPandas()

    plt.figure(figsize=(12,6))
    plt.plot(View5["Hora_inicio"], View5["count"], marker="o", linestyle="-", color="red")

    for x, y in zip(View5["Hora_inicio"], View5["count"]):
        plt.text(x, y * 1.006, str(int(y)), ha='center', va='bottom')

    plt.xlabel("Hora del día")
    plt.ylabel("Cantidad de delitos")
    plt.title("Distribución de delitos por hora del día")
    plt.xticks(range(0,24))
    plt.tight_layout()
    plt.show()