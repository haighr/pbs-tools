-- Norm Olsen's query (greatly modified) to get top N percentage catch
-- Last modified: 2017-06-13 (RH) to access GFFOS' GF_MERGED_CATCH table
SET NOCOUNT ON

@INSERT('meanSppWt.sql')  -- getData now inserts the specified SQL file assuming it's on the path specified in getData

SELECT
  C.SPECIES_CODE,
  (CASE 
    WHEN ISNULL(C.LANDED_KG,0) > 0 THEN C.LANDED_KG
    WHEN ISNULL(C.LANDED_PCS,0) > 0 THEN C.LANDED_PCS * ISNULL(FW.MNWT,0.5)
    ELSE 0 END) AS LANDED,
  (CASE 
    WHEN ISNULL(C.DISCARDED_KG,0) > 0 THEN C.DISCARDED_KG
    WHEN ISNULL(C.DISCARDED_PCS,0) > 0 THEN C.DISCARDED_PCS * ISNULL(FW.MNWT,0.5)
    ELSE 0 END) AS DISCARDED
INTO #ALLCAT
FROM 
  GFFOS.dbo.GF_MERGED_CATCH C
LEFT OUTER JOIN @MEAN_WEIGHT FW ON -- FISH WEIGHTS FW
    C.SPECIES_CODE = FW.SPECIES_CODE
WHERE 
  --ROWNUM <= 100 AND
  --C.SPECIES_CODE  IN (@sppcode) AND
  C.SPECIES_CODE NOT IN ('004','848','849','999','XXX') AND
  C.FISHERY_SECTOR IN ('GROUNDFISH TRAWL', 'JOINT VENTURE TRAWL', 'FOREIGN') AND
  (COALESCE(C.MAJOR_STAT_AREA_CODE,'00') IN (@major) OR COALESCE(C.MINOR_STAT_AREA_CODE,'00') IN (@dummy)) AND
  COALESCE(C.BEST_DEPTH,0) BETWEEN @mindep AND @maxdep AND
  (CASE WHEN
    C.GEAR IN ('BOTTOM TRAWL', 'UNKNOWN TRAWL') 
    THEN 1
  WHEN
    C.GEAR IN ('MIDWATER TRAWL')
  THEN 3 ELSE 0 END) IN (@gear) AND
  C.BEST_DATE >= '1996-02-17'  -- Chose start of observer program to properly compare among all species

DECLARE @total AS FLOAT
SET @total = (SELECT 
  SUM(AC.LANDED + AC.DISCARDED) AS TOTAL
  FROM  #ALLCAT AC )

SELECT TOP @top 
  SP.SPECIES_CDE AS code,
  SP.SPECIES_DESC AS spp,
  SUM(AC.LANDED + AC.DISCARDED)/1e6 AS catKt,
  SUM(AC.LANDED + AC.DISCARDED) / @total * 100 AS pct
--INTO #WASTELAND
FROM
  #ALLCAT AC
  INNER JOIN PacHarvest.dbo.C_Species SP ON
    AC.SPECIES_CODE = SP.SPECIES_CDE
GROUP BY SP.SPECIES_CDE, SP.SPECIES_DESC
ORDER BY SUM(AC.LANDED + AC.DISCARDED) / @total DESC

--select * from #ALLCAT

-- data(species); fish=species$code[species$fish]
-- mess=paste("getData(\"pht_concurrent.sql\",\"PacHarvest\",strSpp=c(\"",paste(fish,collapse="\",\""),"\"),mindep=330,maxdep=500,dummy=1)",sep="") -- all fish
-- eval(parse(text=mess))

-- getData("pht_concurrent.sql","PacHarvest",strSpp="424",mindep=49,maxdep=101,dummy=1)  -- dummy essential to make query work
-- getData("pht_concurrent.sql","PacHarvest",strSpp="396",major=5:7,mindep=70,maxdep=441,dummy=1) -- QCS (567)
-- getData("pht_concurrent.sql","PacHarvest",strSpp="228",major=5:6,dummy=12,mindep=70,maxdep=441,gear=c(1,3)) -- QCS (major 5+6 and minor 12)
-- qu("fos_concurrent.sql",dbName="GFFOS",strSpp="396",major=5:7,mindep=96,maxdep=416,dummy=34,top=20,gear=1) -- QCS (major 567 and minor 34)
