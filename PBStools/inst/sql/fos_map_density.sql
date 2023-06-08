-- Get catch-effort data for mapping density (last modified: 2018-01-23)
SET NOCOUNT ON -- prevent timeout errors

@INSERT('meanSppWt.sql')  -- getData now inserts the specified SQL file assuming it's on the path specified in getData


--SELECT INTO #FOSPAM
SELECT --TOP 20
  MC.TRIP_ID,
  MC.FISHING_EVENT_ID,
  (CASE  --try to match categorisation used in 'fos_mcatORF.sql'
    WHEN MC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL','JOINT VENTURE TRAWL','FOREIGN') THEN 1  -- Trawl
    WHEN MC.FISHERY_SECTOR IN ('HALIBUT','HALIBUT AND SABLEFISH','K/L') THEN 2
    WHEN MC.FISHERY_SECTOR IN ('SABLEFISH') THEN 3
    WHEN MC.FISHERY_SECTOR IN ('LINGCOD','SPINY DOGFISH','SCHEDULE II') THEN 4
    WHEN MC.FISHERY_SECTOR IN ('ROCKFISH INSIDE','ROCKFISH OUTSIDE','ZN','K/ZN') THEN 5
    ELSE 0 END) AS \"fid\",
  (CASE
    WHEN MC.GEAR IN ('BOTTOM TRAWL','UNKNOWN TRAWL') THEN 1                         -- Bottom Trawl
    WHEN MC.GEAR IN ('MIDWATER TRAWL') THEN 2                                       -- Midwater Trawl
    WHEN MC.GEAR IN ('HOOK AND LINE','LONGLINE','LONGLINE OR HOOK AND LINE') THEN 3 -- Hook & Line
    WHEN MC.GEAR IN ('TRAP','TRAP OR LONGLINE OR HOOK AND LINE') THEN 4             -- Trap
    ELSE 0 END) AS GEAR,
  --TO_CHAR(MC.BEST_DATE,'YYYY-MM-DD') AS Edate,  -- SchmOracle
  CONVERT(SMALLDATETIME,CONVERT(char(10),MC.BEST_DATE, 20)) AS Edate,
  CONVERT(INTEGER,REPLACE(ISNULL(MC.VESSEL_REGISTRATION_NUMBER,'0'),'i','1')) AS VRN,
  (CASE
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('01') THEN '4B'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('03') THEN '3C'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('04') THEN '3D'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('05') THEN '5A'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('06') THEN '5B'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('07') THEN '5C'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('08') THEN '5D'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('09') THEN '5E'
    ELSE '00' END) AS PMFC,
  CONVERT(INTEGER, ISNULL(MC.MAJOR_STAT_AREA_CODE,'00')) AS major,
  CONVERT(INTEGER, ISNULL(MC.MINOR_STAT_AREA_CODE,'00')) AS minor,
  ISNULL(MC.LOCALITY_CODE,0) AS locality,
  --ISNULL(to_number(MC.DFO_STAT_AREA_CODE),0) AS PFMA, -- SchmOracle
  --ISNULL(CONVERT(INTEGER,MC.DFO_STAT_AREA_CODE),0) AS PFMA,
  ISNULL(MC.DFO_STAT_AREA_CODE,0) AS PFMA,
  ISNULL(MC.DFO_STAT_SUBAREA_CODE,0) AS PFMS,
  SUM(ISNULL(MC.LONGITUDE,1e-08)) / SUM(CASE WHEN MC.LONGITUDE IS NULL THEN 1e-08 ELSE 1 END) AS X,
  SUM(ISNULL(MC.LATITUDE,1e-08)) / SUM(CASE WHEN MC.LATITUDE IS NULL THEN 1e-08 ELSE 1 END) AS Y,
  --SUM(ISNULL(MC.END_LONGITUDE,1e-08)) / SUM(CASE WHEN MC.END_LONGITUDE IS NULL THEN 1e-08 ELSE 1 END) AS X2,
  --SUM(ISNULL(MC.END_LATITUDE,1e-08)) / SUM(CASE WHEN MC.END_LATITUDE IS NULL THEN 1e-08 ELSE 1 END) AS Y2,
  AVG(COALESCE(MC.BEST_DEPTH,0)) AS depth,  -- already converted to from fathoms to metres in MERGED_CATCH
  SUM(CASE
    WHEN MC.SPECIES_CODE IN (@sppcode) AND MC.LANDED_KG > 0 THEN MC.LANDED_KG
    WHEN MC.SPECIES_CODE IN (@sppcode) AND MC.LANDED_KG = 0 THEN MC.LANDED_PCS * ISNULL(FW.MNWT,0.5)
    ELSE 0 END) AS landed,
  SUM(CASE
    WHEN MC.SPECIES_CODE IN (@sppcode) AND MC.DISCARDED_KG > 0 THEN MC.DISCARDED_KG
    WHEN MC.SPECIES_CODE IN (@sppcode) AND MC.DISCARDED_KG = 0 THEN MC.DISCARDED_PCS * ISNULL(FW.MNWT,0.5)
    ELSE 0 END) AS released,
  AVG(CASE
    WHEN MC.FE_START_DATE IS NOT NULL AND MC.FE_END_DATE IS NOT NULL THEN
      CONVERT(REAL, MC.FE_END_DATE - MC.FE_START_DATE) * 24. * 60. 
    ELSE 0 END) AS effort,   --effort in minutes
  SUM(
    (CASE
      WHEN MC.LANDED_KG > 0 THEN MC.LANDED_KG
      WHEN MC.LANDED_KG = 0 THEN MC.LANDED_PCS * ISNULL(FW.MNWT,0.5)
      ELSE 0 END) +
    (CASE 
      WHEN MC.DISCARDED_KG > 0 THEN MC.DISCARDED_KG
      WHEN MC.DISCARDED_KG = 0 THEN MC.DISCARDED_PCS * ISNULL(FW.MNWT,0.5)
      ELSE 0 END) 
    ) AS totcat
INTO #FOSPAM
FROM GFFOS.dbo.GF_MERGED_CATCH MC LEFT OUTER JOIN
  @MEAN_WEIGHT FW ON -- FISH WEIGHTS FW
    MC.SPECIES_CODE = FW.SPECIES_CODE
GROUP BY
  MC.TRIP_ID, MC.FISHING_EVENT_ID,
  (CASE
    WHEN MC.FISHERY_SECTOR IN ('GROUNDFISH TRAWL','JOINT VENTURE TRAWL','FOREIGN') THEN 1  -- Trawl
    WHEN MC.FISHERY_SECTOR IN ('HALIBUT','HALIBUT AND SABLEFISH','K/L') THEN 2
    WHEN MC.FISHERY_SECTOR IN ('SABLEFISH') THEN 3
    WHEN MC.FISHERY_SECTOR IN ('LINGCOD','SPINY DOGFISH','SCHEDULE II') THEN 4
    WHEN MC.FISHERY_SECTOR IN ('ROCKFISH INSIDE','ROCKFISH OUTSIDE','ZN','K/ZN') THEN 5
    ELSE 0 END),
  (CASE
    WHEN MC.GEAR IN ('BOTTOM TRAWL','UNKNOWN TRAWL') THEN 1                         -- Bottom Trawl
    WHEN MC.GEAR IN ('MIDWATER TRAWL') THEN 2                                       -- Midwater Trawl
    WHEN MC.GEAR IN ('HOOK AND LINE','LONGLINE','LONGLINE OR HOOK AND LINE') THEN 3 -- Hook & Line
    WHEN MC.GEAR IN ('TRAP','TRAP OR LONGLINE OR HOOK AND LINE') THEN 4             -- Trap
    ELSE 0 END),
  CONVERT(SMALLDATETIME,CONVERT(char(10),MC.BEST_DATE, 20)),
  CONVERT(INTEGER,REPLACE(ISNULL(MC.VESSEL_REGISTRATION_NUMBER,'0'),'i','1')),
  (CASE
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('01') THEN '4B'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('03') THEN '3C'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('04') THEN '3D'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('05') THEN '5A'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('06') THEN '5B'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('07') THEN '5C'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('08') THEN '5D'
    WHEN MC.MAJOR_STAT_AREA_CODE IN ('09') THEN '5E'
    ELSE '00' END),
  CONVERT(INTEGER, ISNULL(MC.MAJOR_STAT_AREA_CODE,'00')),
  CONVERT(INTEGER, ISNULL(MC.MINOR_STAT_AREA_CODE,'00')),
  ISNULL(MC.LOCALITY_CODE,0),
  ISNULL(MC.DFO_STAT_AREA_CODE,0),
  ISNULL(MC.DFO_STAT_SUBAREA_CODE,0)

SELECT --TOP 1000
  CONVERT(INTEGER, FP.FID) AS fid,
  FP.X,
  FP.Y,
  FP.X AS X2,
  FP.Y AS Y2,
--  -(CASE WHEN FP.X2 <= 1 THEN 0 ELSE FP.X2 END) AS X2,
--   (CASE WHEN FP.Y2 <= 1 THEN 0 ELSE FP.Y2 END) AS Y2, 
  FP.PMFC, FP.major, FP.minor, FP.locality, FP.PFMA, FP.PFMS,
  FP.depth AS fdep,
  FP.GEAR AS gear,
  --CONVERT(SMALLDATETIME, FP.Edate, 20) AS [date],
  CONVERT(VARCHAR, FP.Edate, 23) AS [date],
  FP.VRN AS cfv,
  FP.effort AS eff, 
  CONVERT(REAL,FP.landed + FP.released) AS @sppcode
INTO #FOSMAP
FROM #FOSPAM FP
WHERE 
  FP.Edate IS NOT NULL
  --AND  FP.Edate>='2006' AND FP.Edate <= (SELECT CONVERT(CHAR(10),CURRENT_TIMESTAMP,23))
  --AND FP.effort > 1 AND FP.effort <= 24*60 -- can do this R
  AND ISNULL(FP.depth,0) <= 1600
  AND ABS(FP.X) > 1 AND ABS(FP.Y) > 1 
--  AND  -FP.X + -FP.X2 < 0
--  AND FP.Y  + FP.Y2 > 0

SELECT *,
  'GMA' = CASE
    WHEN FM.PFMA IN (21,23,24,121,123) OR
          (FM.PFMA IN (124) AND FM.PFMS IN (1,2,3)) OR
          (FM.PFMA IN (125) AND FM.PFMS IN (6)) THEN '3C'
    WHEN FM.PFMA IN (25,26,126) OR
          (FM.PFMA IN (27) AND FM.PFMS IN (2,3,4,5,6,7,8,9,10,11)) OR
          (FM.PFMA IN (124) AND FM.PFMS IN (4)) OR
          (FM.PFMA IN (125) AND FM.PFMS IN (1,2,3,4,5)) OR
          (FM.PFMA IN (127) AND FM.PFMS IN (1,2)) THEN '3D'
    WHEN FM.PFMA IN (13,14,15,16,17,18,19,20,28,29) OR
          (FM.PFMA IN (12) AND FM.PFMS NOT IN (14)) THEN '4B'
    WHEN FM.PFMA IN (11,111) OR
          (FM.PFMA IN (12) AND FM.PFMS IN (14)) OR
          (FM.PFMA IN (27) AND FM.PFMS IN (1)) OR
          (FM.PFMA IN (127) AND FM.PFMS IN (3,4)) OR
          (FM.PFMA IN (130) AND FM.PFMS IN (1)) THEN '5A'
    WHEN FM.PFMA IN (6,106) OR
          (FM.PFMA IN (2) AND FM.PFMS BETWEEN 1 AND 19) OR
          (FM.PFMA IN (102) AND FM.PFMS IN (2)) OR
          (FM.PFMA IN (105) AND FM.PFMS IN (2)) OR
          (FM.PFMA IN (107) AND FM.PFMS IN (1)) OR
          (@sppcode IN ('396','440') AND FM.PFMA IN (102) AND FM.PFMS IN (3)) OR
          -- note: these next lines identify tows in the four-sided polygon SW of Cape St. James
          (@sppcode IN ('396','440') AND COALESCE(FM.X,FM.X2,NULL) IS NOT NULL AND COALESCE(FM.Y,FM.Y2,NULL) IS NOT NULL AND
            -- top, right, bottom, left (note: X already negative)
            COALESCE(FM.Y,FM.Y2)  <= 52.33333 AND
            COALESCE(FM.X,FM.X2)  <= ((COALESCE(FM.Y,FM.Y2)+29.3722978)/(-0.6208634)) AND
            COALESCE(FM.Y,FM.Y2)  >= (92.9445665+(0.3163707*COALESCE(FM.X,FM.X2))) AND
            COALESCE(FM.X,FM.X2)  >= ((COALESCE(FM.Y,FM.Y2)+57.66623)/(-0.83333)) ) THEN '5C'
    WHEN FM.PFMA IN (7,8,9,10,108,109,110) OR
          (@sppcode NOT IN ('396') AND FM.PFMA IN (102) AND FM.PFMS IN (3)) OR
          (FM.PFMA IN (107) AND FM.PFMS IN (2,3)) OR
          (FM.PFMA IN (130) AND FM.PFMS IN (2)) OR
          (FM.PFMA IN (130) AND FM.PFMS IN (3) AND
            COALESCE(FM.Y,FM.Y2,99)<=51.93333) THEN '5B'
    WHEN FM.PFMA IN (3,4,5,103,104) OR
          (FM.PFMA IN (1) AND FM.PFMS IN (2,3,4,5)) OR
          (FM.PFMA IN (101) AND FM.PFMS BETWEEN 4 AND 10) OR
          (FM.PFMA IN (102) AND FM.PFMS IN (1)) OR
          (FM.PFMA IN (105) AND FM.PFMS IN (1)) THEN '5D'
    WHEN FM.PFMA IN (142) OR
          (FM.PFMA IN (1) AND FM.PFMS IN (1)) OR
          (FM.PFMA IN (2) AND FM.PFMS BETWEEN 31 AND 100) OR
          (FM.PFMA IN (101) AND FM.PFMS IN (1,2,3)) OR
          (FM.PFMA IN (130) AND FM.PFMS IN (3) AND 
            COALESCE(FM.Y,FM.Y2,0)>51.93333) THEN '5E'
    ELSE '00' END
FROM #FOSMAP FM

-- Subject matter expert
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="453") -- SST
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="228") -- WAP
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="439") -- RSR
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="439") -- RSR (180925)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="417") -- WWR (180803, 190114, 190530)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="435") -- BOR (190710, 190904, 191022)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="425") -- BSR (200213) -- No catch records!
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="394") -- RER (200213)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="440") -- YMR (180925, 201014, 210125)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="602") -- ARF (210830)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="437") -- CAR (180622, 211125)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="453") -- LST (220307)

-- qu("pht_map_density.sql",dbName="PacHarvest",strSpp="228")
-- getData("pht_map_density.sql","PacHarvest",strSpp="396")
-- getData("fos_map_density.sql","GFFOS",strSpp="394",server="GFSH",type="ORA",trusted=F)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="439",as.is=T)
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="228")
-- qu("fos_map_density.sql",dbName="GFFOS",strSpp="396")  -- POP (230425)

