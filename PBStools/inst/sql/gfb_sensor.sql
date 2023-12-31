-- Get sensor data from GFBioSQL (last revised 2020-10-16)

SET NOCOUNT ON

SELECT --TOP 100000
  SD.SENSOR_DATAFILE_NAME,
  SD.TIME_STAMP,
  -- Note: AVG does not work for temp tables

  -- DEPTH:
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (2) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (2) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (2) THEN 1 ELSE 0 END) END) AS DEPTH,

  -- TEMPERATURE:
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (1) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (1) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (1) THEN 1 ELSE 0 END) END) AS TEMP,

  -- SALINITY:
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (3) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (3) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (3) THEN 1 ELSE 0 END) END) AS SAL,

  -- DISSOLVED OXYGEN:
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (4) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (4) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (4) THEN 1 ELSE 0 END) END) AS DOX,

  -- pH (ACIDITY):
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (6) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (6) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (6) THEN 1 ELSE 0 END) END) AS PH,

  -- CONDUCTIVITY:
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (5) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (5) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (5) THEN 1 ELSE 0 END) END) AS COND,

  -- PRESSURE:
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (11) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (11) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (11) THEN 1 ELSE 0 END) END) AS PRES,

  -- DENSITY:
  SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (12) THEN SD.SENSOR_DATA_VALUE ELSE 0 END) /
  (CASE WHEN SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (12) THEN 1 ELSE 0 END)=0 THEN 1
  ELSE SUM(CASE WHEN SD.SENSOR_DATA_ATTRIBUTE_CODE IN (12) THEN 1 ELSE 0 END) END) AS DENS

INTO #FINE_SENSOR
FROM
  SENSOR_DATA SD
GROUP BY
  SD.SENSOR_DATAFILE_NAME,
  SD.TIME_STAMP

SELECT
  FESD.FISHING_EVENT_ID AS FEID,
  FS.SENSOR_DATAFILE_NAME AS NAME,
  CEILING(FS.DEPTH/1.0) * 1 AS DEPTH,  -- gather average data every metre
  AVG(NULLIF(FS.TEMP,0)) AS TEMP,
  AVG(NULLIF(FS.SAL,0))  AS SAL,
  AVG(NULLIF(FS.DOX,0))  AS DOX,
  AVG(NULLIF(FS.PH,0))   AS PH,
  AVG(NULLIF(FS.COND,0)) AS COND,
  AVG(NULLIF(FS.PRES,0)) AS PRES,
  AVG(NULLIF(FS.DENS,0)) AS DENS
FROM
  #FINE_SENSOR FS
  INNER JOIN FISHING_EVENT_SENSOR_DATAFILE FESD ON
    FS.SENSOR_DATAFILE_NAME = FESD.SENSOR_DATAFILE_NAME
WHERE
  FS.DEPTH IS NOT NULL
GROUP BY
  FESD.FISHING_EVENT_ID,
  FS.SENSOR_DATAFILE_NAME,
  CEILING(FS.DEPTH/1.0) * 1
ORDER BY
  FESD.FISHING_EVENT_ID,
  FS.SENSOR_DATAFILE_NAME,
  CEILING(FS.DEPTH/1.0) * 1

-- qu("gfb_sensor.sql",dbName="GFBioSQL",strSpp="ABC")

