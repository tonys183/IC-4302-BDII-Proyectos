# IC-4302 — Bases de Datos II

Proyectos del curso Bases de Datos II (IC-4302), enfocados en el desarrollo de aplicaciones con bases de datos, la replicación e inteligencia de negocios y el procesamiento de datos para análisis.

## Proyecto I (Aplicación web de apoyo para PYMES)

El proyecto consistía en desarrollar una aplicación web que apoyara la actividad comercial de un emprendimiento o pequeña y mediana empresa, en el contexto de las dificultades provocadas por la pandemia de COVID-19. La propuesta debía permitir el acceso mediante autenticación, administrar información de catálogos y transacciones, y generar reportes parametrizados para consultar datos relevantes de la operación del negocio.

El trabajo incluía el diseño de una base de datos relacional normalizada y su conexión con una aplicación en Java utilizando Oracle en la nube. La solución debía organizarse en capas y utilizar paquetes, procedimientos y funciones PL/SQL para realizar modificaciones y consultas. También se contemplaba una bitácora de auditoría mediante triggers para conservar el registro de determinados cambios y facilitar el seguimiento de la información.

## Proyecto II (Replicación y análisis de datos de alquiler de películas)

El proyecto consistía en construir un entorno de inteligencia de negocios a partir de una base de datos de alquiler de películas. Además de gestionar operaciones como el registro de clientes, alquileres y devoluciones, se debía configurar la replicación lógica en PostgreSQL para mantener una instancia secundaria actualizada y separar el trabajo transaccional del análisis de datos.

La propuesta incorporaba un datamart con un modelo estrella para estudiar la cantidad de alquileres y los ingresos desde distintas perspectivas, como películas, categorías, actores, fechas, ubicaciones y sucursales. A partir de ese modelo se debían construir dashboards en Tableau que permitieran explorar tendencias y comparar resultados para apoyar la toma de decisiones. El trabajo también contemplaba controlar el acceso mediante roles y documentar la alimentación del modelo analítico y la configuración de la réplica.

## Proyecto III (Integración y análisis de datos con SparkSQL)

El proyecto consistía en extraer, transformar e integrar datos de criminalidad del Organismo de Investigación Judicial (OIJ) con indicadores socioeconómicos del Instituto Nacional de Estadística y Censos (INEC). El objetivo era preparar información de distintas fuentes para analizar la distribución de los delitos en Costa Rica y explorar su relación con indicadores como la tasa de ocupación.

El procesamiento debía realizarse con SparkSQL en Python e incluir la limpieza y normalización de los nombres de los distritos, la identificación de registros sin coincidencia y la integración de ambos conjuntos de datos. Los datos limpios se guardarían en PostgreSQL y el análisis se presentaría en un notebook de Jupyter con estadísticas y visualizaciones por distrito, tipo de delito, día de la semana y sexo de las víctimas, junto con interpretaciones y conclusiones sobre los resultados.
