SELECT * FROM TBL_STAFF;

-- 3. CU영수증출력
-- 판매번호, 판매일    ( 헤드쿼리 => 1번쿼리)
------------------------------------------------------------
-- 상품명 , 판매수량, 판매가  
------------------------------------------------------------
-- 총 구매액(이름만찍힘) , 총 구매수량, 총구매액 
------------------------------------------------------------
-- 과세물품가액               (총금액의 10/11) 소수점X )(2번쿼리)
-- 부가세                      (총금액의 1/11) 소수점X
------------------------------------------------------------
-- 결제금액                 ???
-- 결제수단 (신용카드)      ???

-- SALE_DETAIL, SALE, PRODUCT , SALE_DETAIL,SALE_DETAIL,(상품마다SUM 상품코드.판매수량),(상품마다SUM 상품코드.판매수량*상품코드.단가),(상품마다SUM 상품코드.판매수량*상품코드.단가)*10/11,(상품마다SUM 상품코드.판매수량*상품코드.단가)*1/11,결제상세
-- 판매상세번호, 판매일, 상품명, 판매수량, 판매가(단가), 총구매수량, 총구매액, 과세물품가액, 부가세, 결제금액, 결제수단
-- SALE_DETAIL_ID, SALE_DATE, PRODUCT_NAME
SELECT *
FROM TBL_SALE;
SELECT *
FROM TBL_SALE_DETAIL;
SELECT *
FROM TBL_SALE_DETAIL
WHERE SALE_ID = 'SA001';
SELECT * FROM TBL_PAYMENT;
SELECT * FROM TBL_PAYMENT_DETAIL;
SELECT *
FROM TBL_PRODUCT;
DESC TBL_PRODUCT;

-- 상
SELECT 
        s.SALE_ID 판매번호
        ,s.SALE_DATE 판매일
        ,p.PRODUCT_NAME 상품명
        ,sd.QTY 판매수량
        ,sd.PRICE 판매가
FROM TBL_SALE s JOIN TBL_SALE_DETAIL sd ON s.SALE_ID = sd.SALE_ID
                JOIN TBL_PRODUCT p ON sd.PRODUCT_CODE = p.PRODUCT_CODE
WHERE s.SALE_ID = 'SA001'

UNION ALL

SELECT NULL,NULL,'총 구매액',SUM(QTY),SUM(QTY*PRICE)
FROM TBL_SALE_DETAIL
WHERE SALE_ID= 'SA001';
-- 하
SELECT
    TRUNC(pd.TOTAL_AMT*10/11) 과세물품가액
    ,TRUNC(pd.TOTAL_AMT/11) 부가세
    ,pd.TOTAL_DISCOUNT "총 할인금액"
    ,pd.USED_POINT 사용포인트
    ,pd.AMT 결제금액
    ,pd.PAY_METHOD 결제수단
FROM TBL_PAYMENT p JOIN TBL_PAYMENT_DETAIL pd ON p.pay_detail_id = pd.pay_detail_id
WHERE p.sale_id = 'SA001';








-- 4. 환불처리.

SELECT *
FROM TBL_SALE_DETAIL;