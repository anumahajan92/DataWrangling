
--DROP STATEMENTS
DROP TABLE CUSTOMER_DIM;
DROP TABLE LOCATION_DIM;
DROP TABLE COUNTRY_DIM;
DROP TABLE REGION_DIM;
DROP TABLE CUSTOMER_FACT;
DROP TABLE DEPARTMENT_DIM;
DROP TABLE JOB_DIM;
DROP TABLE E_YEARMONTH_DIM;
DROP TABLE EMPLOYEE_FACT;
DROP TABLE SALES_YEARMONTH_DIM;
DROP TABLE SEASON_DIM;
DROP TABLE ORDER_TYPE_DIM;
DROP TABLE PRODUCT_DIM;
DROP TABLE PRO_WARE_DIM;
DROP TABLE WAREHOUSE_DIM;
DROP TABLE ORDER_DIM;
DROP TABLE PROD_ORDER_BRIDGE;
DROP TABLE SALES_TEMP_FACT_REGION;
DROP TABLE SALES_FACT;



-- DIMENTION CUSTOMER_TYPE_DIM
CREATE TABLE CUSTOMER_DIM (
    TYPE_ID   NUMBER GENERATED ALWAYS AS IDENTITY,
    TYPE_DESCRIPTION    VARCHAR2(30),
    LOW_CREDIT_LIMIT    NUMBER,
    HIGH_CREDIT_LIMIT   NUMBER
);

INSERT INTO CUSTOMER_DIM (TYPE_DESCRIPTION,LOW_CREDIT_LIMIT,HIGH_CREDIT_LIMIT) VALUES ('HIGH',3501,99999);
INSERT INTO CUSTOMER_DIM (TYPE_DESCRIPTION,LOW_CREDIT_LIMIT,HIGH_CREDIT_LIMIT) VALUES ('MEDIUM',1501,3500);
INSERT INTO CUSTOMER_DIM (TYPE_DESCRIPTION,LOW_CREDIT_LIMIT,HIGH_CREDIT_LIMIT) VALUES ('LOW',0,1500);
INSERT INTO CUSTOMER_DIM (TYPE_DESCRIPTION,LOW_CREDIT_LIMIT,HIGH_CREDIT_LIMIT) VALUES ('INVALID',NULL,NULL);
COMMIT;

SELECT * FROM CUSTOMER_DIM;

-- DIMENTION LOCATION_DIM
CREATE TABLE LOCATION_DIM AS
        SELECT DISTINCT LOCATION_ID,
                  UPPER (SUBSTR(CITY,1,3)) CITY_ID,
                        STREET_ADDRESS,
                        POSTAL_CODE
          FROM STAGING_LOCATIONS;

SELECT * FROM LOCATION_DIM;


-- DIMENTION COUNTRY_DIM
CREATE TABLE COUNTRY_DIM AS
      SELECT DISTINCT *
        FROM STAGING_COUNTRIES;

SELECT DISTINCT * FROM COUNTRY_DIM;

-- DIMENTION REGION_DIM
CREATE TABLE REGION_DIM AS
      SELECT DISTINCT *
        FROM STAGING_REGIONS;

SELECT * FROM REGION_DIM ;       
        
-- FACT CUSTOMER
CREATE TABLE CUSTOMER_FACT AS
SELECT TYPE_ID, COUNTRY_ID, COUNT(CUSTOMER_ID) AS TOTAL_CUSTOMERS FROM 
    (
        SELECT CASE WHEN C.CREDIT_LIMIT <= 1500 THEN 3
                    WHEN C.CREDIT_LIMIT BETWEEN 1501 AND 3500 THEN 2
                    WHEN C.CREDIT_LIMIT BETWEEN 3501 AND 99999 THEN 1
                    ELSE 4 END AS TYPE_ID,            
               C.COUNTRY_ID,
               C.CUSTOMER_ID
          FROM STAGING_CUSTOMERS C
      )
GROUP BY TYPE_ID,COUNTRY_ID;
          
-- DIMENTION DEPARTMENT
CREATE TABLE DEPARTMENT_DIM AS
SELECT DISTINCT D.DEPARTMENT_ID,
                D.DEPARTMENT_NAME
  FROM STAGING_DEPARTMENTS D;
  
  SELECT * FROM DEPARTMENT_DIM;

CREATE TABLE JOB_DIM AS  
SELECT DISTINCT JOB_ID,JOB_TITLE FROM STAGING_JOBS;

SELECT * FROM JOB_DIM;

-- DIMENTION YEAR_MONTH_DIM
CREATE TABLE E_YEARMONTH_DIM AS
SELECT DISTINCT TO_CHAR(HIRE_DATE,'YYYYMM') YEARMONTH_ID,
       TO_CHAR(HIRE_DATE,'MM') MONTH,
       TO_CHAR(HIRE_DATE,'YYYY') YEAR
FROM STAGING_EMPLOYEES
;

SELECT * FROM E_YEARMONTH_DIM;

-- FACT EMPLOYEE
CREATE TABLE EMPLOYEE_FACT AS 
SELECT D.DEPARTMENT_ID,
       JOB_ID,
       TO_CHAR(HIRE_DATE,'YYYYMM') YEARMONTH,
       D.LOCATION_ID,
       SUM(SALARY) TOTAL_SALARY,
       COUNT(EMPLOYEE_ID) TOTAL_EMPLOYEE
  FROM STAGING_EMPLOYEES E,
       STAGING_DEPARTMENTS D
  WHERE E.DEPARTMENT_ID=D.DEPARTMENT_ID
  GROUP BY D.DEPARTMENT_ID,
           JOB_ID,
           D.LOCATION_ID,
           TO_CHAR(HIRE_DATE,'YYYYMM');
          
SELECT * FROM EMPLOYEE_FACT;

-- CREATE SALES YEAR MONTH DIM 
CREATE TABLE SALES_YEARMONTH_DIM AS
SELECT DISTINCT TO_CHAR(ORDER_DATE,'YYYYMM') YEARMONTH_ID,
       TO_CHAR(ORDER_DATE,'MM') MONTH,
       TO_CHAR(ORDER_DATE,'YYYY') YEAR
FROM STAGING_ORDERS;

-- DIMENTION SEASON_DIM
CREATE TABLE SEASON_DIM (
    SEASON_ID     NUMBER GENERATED ALWAYS AS IDENTITY,
    SEASON_DESC   VARCHAR2(10),
    START_DATE    DATE,
    END_DATE      DATE
);

INSERT INTO SEASON_DIM (SEASON_DESC,START_DATE,END_DATE) VALUES( 'SPRING',TO_DATE('01-09','DD-MM'),TO_DATE('30-11','DD-MM') );
INSERT INTO SEASON_DIM (SEASON_DESC,START_DATE,END_DATE) VALUES( 'SUMMER',TO_DATE('01-12','DD-MM'),TO_DATE('28-02','DD-MM') );
INSERT INTO SEASON_DIM (SEASON_DESC,START_DATE,END_DATE) VALUES( 'AUTUMN',TO_DATE('01-03','DD-MM'),TO_DATE('31-05','DD-MM') );
INSERT INTO SEASON_DIM (SEASON_DESC,START_DATE,END_DATE) VALUES( 'WINTER',TO_DATE('01-06','DD-MM'),TO_DATE('31-08','DD-MM') );
SELECT * FROM SEASON_DIM;

-- DIMENTION ORDER TYPE 
CREATE TABLE ORDER_TYPE_DIM AS
      SELECT ROWNUM AS TYPE_ID,
             ORDER_TYPE
        FROM
            ( SELECT DISTINCT
               UPPER (ORDER_MODE) AS ORDER_TYPE
                FROM STAGING_ORDERS  );

-- DIMENTSION PRODUCT

CREATE TABLE PRODUCT_DIM AS
SELECT DISTINCT SP.PRODUCT_ID,
                SP.PRODUCT_NAME,
                SP.PRODUCT_DESCRIPTION,
                SP.CATEGORY_ID,
          ROUND (1.0 / COUNT(SI.WAREHOUSE_ID),2) AS WEIGHTFACTOR,
        LISTAGG (SI.WAREHOUSE_ID,'_') WITHIN GROUP (ORDER BY SI.WAREHOUSE_ID) AS WAREHOUSE_GROUPLIST
           FROM STAGING_PRODUCTS SP,
                STAGING_INVENTORIES SI
          WHERE SP.PRODUCT_ID = SI.PRODUCT_ID
          GROUP BY SP.PRODUCT_ID,
                   SP.PRODUCT_NAME,
                   SP.PRODUCT_DESCRIPTION,
                   SP.CATEGORY_ID;
                   
SELECT * FROM PRODUCT_DIM;

-- DIMENTION PRO_WARE_DIM
CREATE TABLE PRO_WARE_DIM AS
SELECT * 
  FROM STAGING_INVENTORIES;

-- DIMENTION WAREHOUSE_DIM 
CREATE TABLE WAREHOUSE_DIM AS
SELECT DISTINCT WAREHOUSE_ID,
                WAREHOUSE_NAME 
  FROM STAGING_WAREHOUSES;
  
  SELECT * FROM WAREHOUSE_DIM;
  
--ORDER DIMENSION
CREATE TABLE ORDER_DIM AS
SELECT DISTINCT O.ORDER_ID,
TO_CHAR(ORDER_DATE,'DD-MM-YYYY') AS ORDER_DATE,
ORDER_MODE,
PROMOTION_ID,
ROUND (1.0 / COUNT(PD.PRODUCT_ID),2) AS PRODUCT_WEIGHT_FACTOR,
LISTAGG (PD.PRODUCT_ID,'_') WITHIN GROUP (ORDER BY PD.PRODUCT_ID) AS PRODUCT_GROUPLIST
FROM STAGING_ORDERS O,
STAGING_ORDER_ITEMS PD
WHERE O.ORDER_ID=PD.ORDER_ID
GROUP BY  O.ORDER_ID,
TO_CHAR(ORDER_DATE,'DD-MM-YYYY'),
ORDER_MODE,
PROMOTION_ID;

CREATE TABLE PROD_ORDER_BRIDGE AS
SELECT DISTINCT ORDER_ID,PRODUCT_ID FROM STAGING_ORDER_ITEMS;

  
--------------------------------------------------- SALES FACT USING LOCATION ------------------------------------------------------------
/*
--- TEMP FACT FOR SALES
CREATE TABLE SALES_TEMP_FACT AS
SELECT O.ORDER_ID,
       O.TOTAL_PRICE,
       R.REGION_ID,
      OI.PRODUCT_ID,
       TO_DATE(TO_CHAR(O.ORDER_DATE,'DD-MM-YYYY'),'DD-MM-YYYY') AS ORDER_DATES,
       TO_CHAR(O.ORDER_DATE,'YYYYMM') AS YEARMONTH_ID,
       O.ORDER_MODE 
  FROM STAGING_ORDERS O,
       STAGING_CUSTOMERS C,
       STAGING_COUNTRIES L,
       STAGING_REGIONS R,
       STAGING_ORDER_ITEMS OI
 WHERE O.CUSTOMER_ID = C.CUSTOMER_ID
   AND O.ORDER_ID = OI.ORDER_ID
   AND C.COUNTRY_ID = L.COUNTRY_ID
   AND L.REGION_ID= R.REGION_ID;
   
-- ALTER TEMP FACT 
ALTER TABLE SALES_TEMP_FACT 
  ADD (SEASON_ID NUMBER);

-- UPDATE TEMP FACT 
UPDATE SALES_TEMP_FACT 
   SET SEASON_ID = 1 
 WHERE EXTRACT(MONTH FROM order_dates)
BETWEEN 9 AND 11 ; -- 692

UPDATE SALES_TEMP_FACT 
   SET SEASON_ID = 3 
 WHERE EXTRACT(MONTH FROM order_dates)
BETWEEN 3 AND 5 ; -- 692

UPDATE SALES_TEMP_FACT 
   SET SEASON_ID = 4
 WHERE EXTRACT(MONTH FROM order_dates)
BETWEEN 6 AND 8 ; -- 692
   
UPDATE SALES_TEMP_FACT SET SEASON_ID = 2
 WHERE SEASON_ID IS NULL;  --1340
COMMIT;

CREATE TABLE SALES_FACT AS (
        SELECT PRODUCT_ID,
               SEASON_ID,
               REGION_ID,
               YEARMONTH_ID,
               ORDER_MODE,
               COUNT(ORDER_ID) AS TOTAL_ORDERS,
               SUM(TOTAL_PRICE) AS TOTAL_PRICE
          FROM SALES_TEMP_FACT
          GROUP BY PRODUCT_ID,
                   SEASON_ID,
                   REGION_ID,
                   YEARMONTH_ID,
                   ORDER_MODE );
                                      
-- TEMPORAL

UPDATE STAGING_PROMOTIONS
   SET START_DATE = ( SELECT TO_DATE(TO_CHAR(MIN(ORDER_DATE),'DD-MM-YYYY'),'DD-MM-YYYY')
                        FROM STAGING_ORDERS ),
       END_DATE = TO_DATE('31-12-9999','DD-MM-YYYY')
 WHERE PROMOTION_ID = 1;
 
--- CREATE THE TEMPORAL ---

CREATE TABLE PRODUCT_PRICE_TEMPORAL AS (
    SELECT DISTINCT D.PRODUCT_ID,
                    D.PRODUCT_NAME,
                    B.START_DATE,
                    B.END_DATE,
                    C.UNIT_PRICE*(1-B.VALUE) AS EFFECTIVE_PRICE,
                    B.PRO_DESC AS REMARKS
      FROM STAGING_ORDERS A,
           STAGING_PROMOTIONS B,
           STAGING_ORDER_ITEMS C,
           STAGING_PRODUCTS D
     WHERE A.PROMOTION_ID = B.PROMOTION_ID
       AND A.ORDER_ID = C.ORDER_ID
       AND C.PRODUCT_ID = D.PRODUCT_ID );
       
       SELECT * FROM PRODUCT_PRICE_TEMPORAL WHERE PRODUCT_ID=2319 ORDER BY PRODUCT_ID,START_DATE DESC;
   */    
       
       /*  
       DROP TABLE ORDERS_BKP;
       CREATE TABLE ORDERS_BKP AS SELECT * FROM STAGING_ORDERS;
       UPDATE ORDERS_BKP SET PROMOTION_ID = 1 WHERE ORDER_DATE BETWEEN TO_DATE('01-01-00','DD-MM-YY') AND TO_dATE('31-05-07','DD-MM-YY');
       UPDATE ORDERS_BKP SET PROMOTION_ID = 6 WHERE ORDER_DATE BETWEEN TO_DATE('01-07-07','DD-MM-YY') AND TO_dATE('09-11-07','DD-MM-YY');
       UPDATE ORDERS_BKP SET PROMOTION_ID = 7 WHERE ORDER_DATE BETWEEN TO_DATE('12-11-07','DD-MM-YY') AND TO_dATE('30-11-07','DD-MM-YY');
       UPDATE ORDERS_BKP SET PROMOTION_ID = 8 WHERE ORDER_DATE BETWEEN TO_DATE('01-01-08','DD-MM-YY') AND TO_dATE('31-05-08','DD-MM-YY');
       UPDATE ORDERS_BKP SET PROMOTION_ID = 9 WHERE ORDER_DATE BETWEEN TO_DATE('01-07-08','DD-MM-YY') AND TO_dATE('31-12-99','DD-MM-YY');
      */
	  
--------------------------------------------------- SALES FACT USING REGION ------------------------------------------------------------

CREATE TABLE SALES_TEMP_FACT_REGION AS
 SELECT O.ORDER_ID,
        O.TOTAL_PRICE,
        C.COUNTRY_ID,
        TO_DATE(TO_CHAR(O.ORDER_DATE,'DD-MM-YYYY'),'DD-MM-YYYY') AS ORDER_DATES,
        TO_CHAR(O.ORDER_DATE,'YYYYMM') AS YEARMONTH_ID,
        O.ORDER_MODE 
FROM STAGING_ORDERS O,
     STAGING_CUSTOMERS C
WHERE O.CUSTOMER_ID=C.CUSTOMER_ID  ;
	  
  
  
-- ALTER TEMP FACT 
ALTER TABLE SALES_TEMP_FACT_REGION 
  ADD (SEASON_ID NUMBER);
SELECT * FROM SALES_TEMP_FACT_REGION;---106
-- UPDATE TEMP FACT 
UPDATE SALES_TEMP_FACT_REGION 
   SET SEASON_ID = 1 
 WHERE EXTRACT(MONTH FROM order_dates)
BETWEEN 9 AND 11 ; -- 31

UPDATE SALES_TEMP_FACT_REGION 
   SET SEASON_ID = 3 
 WHERE EXTRACT(MONTH FROM order_dates)
BETWEEN 3 AND 5 ; -- 22

UPDATE SALES_TEMP_FACT_REGION 
   SET SEASON_ID = 4
 WHERE EXTRACT(MONTH FROM order_dates)
BETWEEN 6 AND 8 ; -- 35
   
UPDATE SALES_TEMP_FACT_REGION SET SEASON_ID = 2
 WHERE SEASON_ID IS NULL;  --133
COMMIT;


CREATE TABLE SALES_FACT AS (
        SELECT ORDER_ID,
               SEASON_ID,
               COUNTRY_ID,
               YEARMONTH_ID,
               ORDER_MODE,
               COUNT(ORDER_ID) AS TOTAL_ORDERS,
               SUM(TOTAL_PRICE) AS TOTAL_PRICE
          FROM SALES_TEMP_FACT_REGION
          GROUP BY ORDER_ID,
                   SEASON_ID,
                   COUNTRY_ID,
                   YEARMONTH_ID,
                   ORDER_MODE );
 
select 
select * from SALES_FACT