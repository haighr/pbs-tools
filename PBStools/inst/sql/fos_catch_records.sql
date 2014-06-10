-- Query species catch from GFFOS on GFSH
SELECT 
  (CASE
    WHEN FC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL') THEN 1
    WHEN FC.FISHERY_SECTOR IN ('HALIBUT','HALIBUT AND SABLEFISH') THEN 2
    WHEN FC.FISHERY_SECTOR IN ('SABLEFISH') THEN 3
    WHEN FC.FISHERY_SECTOR IN ('LINGCOD','SPINY DOGFISH') THEN 4
    WHEN FC.FISHERY_SECTOR IN ('ROCKFISH INSIDE','ROCKFISH OUTSIDE') THEN 5
    ELSE 0 END) AS FID,
  FC.TRIP_ID AS TID,
  FC.FISHING_EVENT_ID AS FEID,
  HS.HAIL_NUMBER AS \"hail\",
  HS.SET_NUMBER  AS \"set\",
  NVL(FC.DATA_SOURCE_CODE,0) AS \"log\",
  NVL(FC.LON,NULL) AS X, 
  NVL(FC.LAT,NULL) AS Y,
  FC.BEST_DATE AS \"date\", 
  NVL(TO_CHAR(FC.BEST_DATE,'YYYY'),'9999') AS \"year\",
  NVL(FC.MAJOR_STAT_AREA_CODE,'0') AS \"major\",
  NVL(FC.MINOR_STAT_AREA_CODE,'0') AS \"minor\",
  NVL(FC.LOCALITY_CODE,0) AS \"locality\",
  NVL(FC.DFO_STAT_AREA_CODE,'0') AS \"pfma\",
  NVL(FC.DFO_STAT_SUBAREA_CODE,0) AS \"pfms\",
  NVL(FC.BEST_DEPTH_FM,0) * 6. * 0.3048 AS \"depth\",  -- convert fathoms to metres
  NVL(FC.VESSEL_REGISTRATION_NUMBER,0) AS \"vessel\",
  CASE
    WHEN FC.GEAR IN ('TRAWL') AND FC.GEAR_SUBTYPE NOT IN ('MIDWATER TRAWL') THEN 1
    WHEN FC.GEAR IN ('TRAP') THEN 2
    WHEN FC.GEAR IN ('TRAWL') AND FC.GEAR_SUBTYPE IN ('MIDWATER TRAWL') THEN 3
    WHEN FC.GEAR IN ('HOOK AND LINE') THEN 4
    WHEN FC.GEAR IN ('LONGLINE') THEN 5
    WHEN FC.GEAR IN ('LONGLINE OR HOOK AND LINE','TRAP OR LONGLINE OR HOOK AND LINE') THEN 8
    ELSE 0 END AS \"gear\",
  NVL(HS.SUCCESS_CODE,0) AS \"success\",
  CASE WHEN FC.START_DATE IS NOT NULL AND FC.END_DATE IS NOT NULL THEN
    TO_NUMBER(FC.END_DATE - FC.START_DATE) * 24. * 60. ELSE 0 END AS \"effort\",   --effort in minutes
  CC.landed+CC.released+CC.liced+CC.bait AS \"catKg\",
  CASE
    WHEN (CC.landed+CC.released+CC.liced+CC.bait) = 0 THEN 0
    ELSE (CC.released+CC.liced+CC.bait)/(CC.landed+CC.released+CC.liced+CC.bait)
    END AS \"pdis\",  -- proportion discarded
  CASE
    WHEN CC.totcat = 0 THEN 0
    ELSE (CC.landed+CC.released+CC.liced+CC.bait)/CC.totcat
    END AS \"pcat\"   -- proportion of total catch
FROM 
  -- HAIL & SET HS
  (SELECT
    FE.TRIP_ID,
    FE.FISHING_EVENT_ID,
    NVL(TH.HAIL_NUMBER,0) AS HAIL_NUMBER,
    NVL(FE.SET_NUMBER,9999) AS SET_NUMBER,
    NVL(TS.SUCCESS_CODE,0) AS SUCCESS_CODE
  FROM
    (SELECT
      H.TRIP_ID,
      Min(H.HAIL_NUMBER) AS HAIL_NUMBER
    FROM  GFFOS.GF_HAIL_NUMBER H 
    WHERE H.HAIL_TYPE='OUT'
    GROUP BY  H.TRIP_ID
    ORDER BY  H.TRIP_ID) TH RIGHT OUTER JOIN

  GFFOS.GF_FISHING_EVENT FE ON
    TH.TRIP_ID = FE.TRIP_ID LEFT OUTER JOIN 
  GFFOS.GF_FE_TRAWL_SPECS TS
    ON FE.FISHING_EVENT_ID = TS.FISHING_EVENT_ID
  ORDER BY FE.TRIP_ID, FE.FISHING_EVENT_ID) HS INNER JOIN

-- OFFICIAL CATCH FC
  GFFOS.GF_D_OFFICIAL_FE_CATCH FC
    ON FC.TRIP_ID = HS.TRIP_ID AND
    FC.FISHING_EVENT_ID = HS.FISHING_EVENT_ID INNER JOIN

-- SPECIES CATCH CC
  (SELECT
    OC.TRIP_ID,
    OC.FISHING_EVENT_ID,
    Sum(CASE
      WHEN OC.SPECIES_CODE IN (@sppcode) THEN NVL(OC.LANDED_ROUND_KG,0)
      ELSE 0 END) AS landed,
    Sum(CASE
      WHEN OC.SPECIES_CODE IN (@sppcode) THEN
        COALESCE(OC.TOTAL_RELEASED_ROUND_KG,
        (NVL(OC.SUBLEGAL_RELEASED_COUNT,0) + NVL(OC.LEGAL_RELEASED_COUNT,0)) * FW.MNWT, 0)
      ELSE 0 END) AS released,
    Sum(CASE
      WHEN OC.SPECIES_CODE IN (@sppcode) THEN
        (NVL(OC.SUBLEGAL_LICED_COUNT,0) + NVL(OC.LEGAL_LICED_COUNT,0)) * FW.MNWT
      ELSE 0 END) AS liced,
    Sum(CASE
      WHEN OC.SPECIES_CODE IN (@sppcode) THEN
        (NVL(OC.SUBLEGAL_BAIT_COUNT,0) + NVL(OC.LEGAL_BAIT_COUNT,0)) * FW.MNWT
      ELSE 0 END) AS bait,
    Sum(
      NVL(OC.LANDED_ROUND_KG,0) +
      COALESCE(OC.TOTAL_RELEASED_ROUND_KG,
      (NVL(OC.SUBLEGAL_RELEASED_COUNT,0) + NVL(OC.LEGAL_RELEASED_COUNT,0)) * FW.MNWT, 0) +
      (NVL(OC.SUBLEGAL_LICED_COUNT,0) + NVL(OC.LEGAL_LICED_COUNT,0)) * FW.MNWT +
      (NVL(OC.SUBLEGAL_BAIT_COUNT,0) + NVL(OC.LEGAL_BAIT_COUNT,0)) * FW.MNWT
    ) AS totcat
  FROM GFFOS.GF_D_OFFICIAL_FE_CATCH OC INNER JOIN

-- FISH WEIGHTS FW
  GFFOS.MEAN_SPECIES_WEIGHT_VW FW ON
    OC.SPECIES_CODE = FW.SPP
  GROUP BY OC.TRIP_ID, OC.FISHING_EVENT_ID ) CC ON
    FC.TRIP_ID = CC.TRIP_ID AND
    FC.FISHING_EVENT_ID = CC.FISHING_EVENT_ID 

WHERE 
  FC.SPECIES_CODE IN (@sppcode) AND 
  (FC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL') OR 
  (FC.FISHERY_SECTOR NOT IN ('GROUNDFISH TRAWL') AND NVL(FC.DATA_SOURCE_CODE,0) NOT IN (106,107)))

ORDER BY FC.TRIP_ID, FC.FISHING_EVENT_ID
;
-- getData("fos_catch_records.sql","GFFOS",strSpp="415",server="GFSH",type="ORA",path=.getSpath(),trusted=F,uid=Sys.info()["user"],pwd="")
-- getData("fos_catch_records.sql","GFFOS",strSpp="396",server="GFSH",type="ORA",trusted=F,uid=Sys.info()["user"],pwd="")
-- getData("fos_catch_records.sql","GFFOS",strSpp="418",server="GFSH",type="ORA",path=.getSpath(),trusted=F,uid=Sys.info()["user"],pwd="")
