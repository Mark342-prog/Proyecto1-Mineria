
# Maternidad Adolescente en Guatemala (2009–2023)

## Descripción del Proyecto

Análisis cuantitativo de la evolución temporal, distribución territorial y factores asociados a los nacimientos en madres menores de 18 años en Guatemala durante el período 2009–2023. El estudio utiliza registros administrativos del Instituto Nacional de Estadística (INE) y técnicas de análisis estadístico descriptivo y clustering territorial.

## Motivación

La maternidad adolescente representa un fenómeno complejo que refleja desigualdades estructurales en educación, salud y desarrollo social. Este proyecto busca:

- Identificar patrones temporales y territoriales del fenómeno
- Cuantificar la relación entre educación y maternidad temprana
- Detectar concentraciones geográficas mediante clustering
- Generar evidencia para la formulación de políticas públicas focalizadas

## Preguntas de Investigación

1. ¿Cómo ha evolucionado la proporción de maternidad adolescente entre 2009 y 2023?
2. ¿Existen diferencias territoriales significativas entre departamentos?
3. ¿Qué relación existe entre nivel educativo y maternidad temprana?
4. ¿Se observan diferencias según grupo étnico?
5. ¿Existe asociación entre educación y lugar de ocurrencia del nacimiento?
6. ¿Se identifican patrones de agrupamiento territorial estadísticamente significativos?

## Estructura del Proyecto

```
proyecto-maternidad-adolescente/
│
├── Datos/                      # Archivos .sav del INE (2009-2023)
├── Proyecto1.Rmd              # Documento principal de análisis
├── Proyecto1.html             # Reporte generado
└── README.md                  # Este archivo
```

## Metodología

### Enfoque Analítico
- **Tipo de estudio**: Cuantitativo, descriptivo, longitudinal
- **Fuente de datos**: Registros administrativos de nacimientos (INE)
- **Período**: 2009–2023
- **Unidad de análisis**: Nacimientos registrados oficialmente

### Variables Principales

| Variable | Descripción | Tipo |
|----------|-------------|------|
| `Añoreg` | Año de registro | Numérica |
| `Edadm` | Edad de la madre | Numérica |
| `Escolam` | Nivel educativo de la madre | Categórica |
| `Pueblopm` | Grupo étnico de la madre | Categórica |
| `Sitioocu` | Lugar de ocurrencia del nacimiento | Categórica |
| `Deprem` | Departamento de residencia | Categórica |

### Técnicas Aplicadas

1. **Análisis Descriptivo**
   - Distribución de frecuencias
   - Proporciones anuales y territoriales
   - Análisis bivariado (educación, etnia, lugar de ocurrencia)

2. **Análisis Territorial**
   - Identificación de departamentos con valores extremos
   - Construcción de indicadores agregados por departamento

3. **Clustering K-means**
   - Agrupamiento territorial basado en perfiles multivariados
   - Validación mediante índice de silhouette
   - Método del codo para selección de k óptimo

## Requisitos Técnicos

### Software
- R (versión 4.0 o superior)
- RStudio (recomendado)

### Librerías R

```r
install.packages(c("haven", "dplyr", "ggplot2", "cluster", "factoextra"))
```

### Librerías Utilizadas

- `haven`: Lectura de archivos .sav (SPSS)
- `dplyr`: Manipulación y transformación de datos
- `ggplot2`: Visualización de datos
- `cluster`: Análisis de clustering
- `factoextra`: Visualización de resultados de clustering

## Cómo Ejecutar el Proyecto

### 1. Preparación de Datos

Coloca los archivos `.sav` del INE en la carpeta `Datos/`:

```
Datos/
├── nacimientos_2009.sav
├── nacimientos_2010.sav
├── ...
└── nacimientos_2023.sav
```

### 2. Ejecución del Análisis

**Opción A: Desde RStudio**

1. Abre `Proyecto1.Rmd` en RStudio
2. Haz clic en "Knit" → "Knit to HTML" (o PDF)
3. El reporte se generará automáticamente

**Opción B: Desde consola R**

```r
render("Proyecto1.Rmd", output_format = "html_document")
```

### 3. Salidas Generadas

- `Proyecto1.html`: Reporte interactivo con todos los análisis y gráficos
- Visualizaciones embebidas en el documento

## Principales Hallazgos

### 1. Evolución Temporal
- **Pico máximo**: 2012 (~10.7% de nacimientos en madres <18 años)
- **Tendencia descendente**: 2013-2020
- **Mínimo observado**: 2020 (~7.3%)
- **Repunte reciente**: Leve aumento en 2023

### 2. Factor Educativo
Relación inversa clara entre educación y maternidad adolescente:
- Ninguno: 9.5%
- Primaria: 5.2%
- Básica: 2.8%
- Diversificado: 0.5%
- Universitario: ~0%

### 3. Desigualdad Territorial
- Variación significativa entre departamentos (5% - 12%)
- Tres perfiles territoriales identificados mediante clustering:
  - **Cluster 1**: Menor prevalencia, mayor educación superior
  - **Cluster 2**: Perfil intermedio, transición
  - **Cluster 3**: Alta vulnerabilidad, mayor prevalencia y baja educación

### 4. Validación Estadística
- Índice de silhouette promedio: **0.53** (estructura moderadamente clara)
- Confirma existencia de patrones territoriales diferenciados

## Limitaciones del Estudio

- Basado únicamente en nacimientos registrados oficialmente
- Posible subregistro en áreas rurales remotas
- Calidad de datos dependiente de registros administrativos
- No incluye análisis causal ni inferencia estadística multivariada

## Aplicaciones Potenciales

- Diseño de intervenciones territoriales focalizadas
- Priorización de programas educativos y de salud sexual
- Evaluación de impacto de políticas públicas previas
- Identificación de zonas de alta vulnerabilidad social

## Autores

**Grupo 6**  
Proyecto 1 – Análisis de Datos

## Licencia

Este proyecto tiene fines académicos y de investigación.

---

**Fecha de última actualización**: Febrero 2026
