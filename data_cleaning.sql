USE laptopdb;


#Step1 - Creating backup 
-- Method 1
CREATE TABLE laptops_bakcup2 LIKE laptops;
INSERT INTO laptops_bakcup
SELECT * FROM laptops;


ALTER TABLE laptop RENAME laptops;

#Method 2
CREATE TABLE backup_laptop AS (SELECT * FROM laptop);
SELECT * FROM backup_laptop;



#Step2 - Know the shape
#> 1303 rows , col we can see

#Step 3 - know the memory consumption 
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'laptopdb'
AND TABLE_NAME = 'laptops';
#--> taking around 272 kb space


#Step4 -> Drop unimportant columns
SELECT * FROM laptops;
ALTER TABLE laptops 
DROP COLUMN `Unnamed: 0` ;


#Step 5 --> Drop Null values(all)
WITH temp_table AS (SELECT `index` FROM laptops
				WHERE Company IS NULL AND TypeName IS NULL AND Inches IS NULL
				AND ScreenResolution IS NULL AND Cpu IS NULL AND Ram IS NULL
				AND Memory IS NULL AND Gpu IS NULL AND OpSys IS NULL AND
				WEIGHT IS NULL AND Price IS NULL)                
DELETE  FROM laptops 
WHERE `index` IN (SELECT * FROM temp_table);
                
SELECT * FROM laptops;
                
#Step6 --> Drop duplicates
#No duplicates present in our data

#Step7-->Clean ram change column data type
#-->we can use distinct for catergorical column

SELECT * FROM laptops;

SELECT DISTINCT(TypeName)
FROM laptops;

#-----------------------inches column
#Inches column should be numerical not string hence changing it's data type

#Note - index 476 inches column has ? value deleting  it first then we can do conversion
DELETE FROM laptops
WHERE `index` = 476;

ALTER TABLE laptops
MODIFY COLUMN Inches DECIMAL(10,1);

SELECT * FROM laptops
WHERE Inches LIKE '%?%';

#-----------------------ram column
UPDATE laptops
SET Ram = trim(REPLACE(Ram, 'GB', ''));

SELECT * FROM laptops;

ALTER TABLE laptops
MODIFY COLUMN Ram INTEGER;

#-----------------------Weight column
SELECT * FROM laptops;

UPDATE laptops
SET Weight = trim(REPLACE(Weight, "kg",''));

ALTER TABLE laptops
MODIFY COLUMN Weight DECIMAL(10,1);

DELETE FROM laptops
WHERE `index` = 208;

#---------------------------Price
SELECT * FROM laptops;

UPDATE laptops
SET Price = ROUND(Price);

ALTER TABLE laptops
MODIFY COLUMN Price INTEGER;


#---------------------OpSys
SELECT 	DISTINCT(`OpSys`) FROM laptops;
-- mac
-- Windows
-- No os
-- linux
-- Android/Chrome (other)


SELECT OpSys,
CASE
	WHEN OpSys LIKE '%windows%' THEN 'windows'	
	WHEN OpSys LIKE '%mac%' THEN 'mac'	
	WHEN OpSys LIKE '%No Os%' THEN 'N/A'	
	WHEN OpSys LIKE '%linux%' THEN 'linux'	
    
    ELSE 'other'
END AS 'os_brand'
FROM laptops;

UPDATE laptops
SET OpSys = CASE
	WHEN OpSys LIKE '%windows%' THEN 'windows'	
	WHEN OpSys LIKE '%mac%' THEN 'mac'	
	WHEN OpSys LIKE '%No Os%' THEN 'N/A'	
	WHEN OpSys LIKE '%linux%' THEN 'linux'	
    ELSE 'other'
    END;

SELECT * FROM laptops;

# Making gpu_name and gpu_brand columns from gpu column

ALTER TABLE laptops
ADD COLUMN gpu_brand VARCHAR(255) AFTER Gpu;

ALTER TABLE laptops
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

SELECT * FROM laptops;

UPDATE laptops
SET gpu_brand = (
	SELECT SUBSTRING_INDEX(Gpu, ' ', 1)
	FROM (SELECT `index`, Gpu FROM laptops) AS tmp
	WHERE tmp.`index` = laptops.`index`
);

UPDATE laptops l1 
SET l1.gpu_name = (SELECT REPLACE(Gpu,gpu_brand,'') 
                   FROM (SELECT * FROM laptops) l2 
                   WHERE l2.index = l1.index);

ALTER TABLE laptops DROP COLUMN Gpu;
SELECT * FROM laptops;

# making cpu_brand and cpu_name from 
ALTER TABLE laptops
ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_name;

SELECT * FROM laptops;

UPDATE laptops l1 
JOIN laptops l2 ON l1.index = l2.index 
SET l1.cpu_brand = SUBSTRING_INDEX(l2.Cpu, ' ', 1);


UPDATE laptops l1 
JOIN laptops l2 ON l1.index = l2.index 
SET l1.cpu_speed = CAST(REPLACE(SUBSTRING_INDEX(l2.Cpu, ' ', -1), 'GHz', '') AS DECIMAL(10,2));


UPDATE laptops l1
JOIN laptops l2 ON l1.index = l2.index
SET l1.cpu_name = REPLACE(REPLACE(l2.Cpu, l2.cpu_brand, ''), SUBSTRING_INDEX(REPLACE(l2.Cpu, l2.cpu_brand, ''), ' ', -1), '');

SELECT * FROM laptops;
ALTER TABLE laptops DROP COLUMN Cpu;


#=============================================================
# Making three columns out of  ScreenResolution -resolution widht, resolution heighy and touchscreen

SELECT ScreenResolution,substring_index(substring_index(ScreenResolution,' ',-1),'x',1),
substring_index(substring_index(ScreenResolution,' ',-1),'x',-1) FROM laptops;

select * from laptops;

ALTER TABLE laptops
ADD column resolution_width INTEGER AFTER ScreenResolution,
ADD column resolution_height INTEGER AFTER resolution_width ;

UPDATE laptops
SET resolution_width = substring_index(substring_index(ScreenResolution,' ',-1),'x',1),
resolution_height = substring_index(substring_index(ScreenResolution,' ',-1),'x',-1);

ALTER TABLE laptops
ADD column touchscreen INTEGER AFTER resolution_height;

select * from laptops;

SELECT ScreenResolution LIKE '%Touch%' FROM laptops;

UPDATE laptops
SET touchscreen = ScreenResolution LIKE '%Touch%';

ALTER TABLE laptops
DROP ScreenResolution;


#================================================================================
-- removing unnecessory details after core i5

SELECT cpu_name, substring_index(trim(cpu_name),' ',2) FROM laptops;

UPDATE laptops
SET
cpu_name = substring_index(trim(cpu_name),' ',2);

select * from laptops;

#================================================================================
-- breaking memory into three new columns memory_type,primary_sotrage, seconday_storage

ALTER TABLE laptops
ADD column memory_type  VARCHAR(255) after Memory,
ADD column primary_storage INTEGER after memory_type,
ADD column secondary_storage INTEGER after primary_storage;

select * from laptops;

SELECT Memory,
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END AS 'memory_type'
FROM laptops;

UPDATE laptops
SET memory_type = CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END;

select * from laptops;

SELECT Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END
FROM laptops;

UPDATE laptops
SET primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
secondary_storage = CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END;

SELECT 
primary_storage,
CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
secondary_storage,
CASE WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END FROM laptops;


UPDATE laptops
SET primary_storage = CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
secondary_storage = CASE WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END;

SELECT * FROM laptops;

ALTER TABLE laptops DROP COLUMN gpu_name;

SELECT * FROM laptops;





































