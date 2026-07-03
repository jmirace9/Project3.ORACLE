-- 재고 테이블 product_code UNIQUE 제약조건 주기
ALTER TABLE tbl_stock
ADD CONSTRAINT uq_stock_product_code UNIQUE(product_code);

구매 데이터 조회 (SELECT로 현재 상태 보여주기)
EXEC UP_RECEIPT('SA002'); → 구매 영수증 출력
EXEC UP_REFUND('SA002'); → 환불 처리
재고(TBL_STOCK)와 환불 로그(TBL_PAYMENT, TBL_SALE_DETAIL, TBL_STOCK_DETAIL) 조회
EXEC UP_RECEIPT('SA002'); → 환불 영수증 출력

-- 현재 SA001, 002 로 연습

--1)
SELECT *
FROM TBL_PAYMENT
WHERE SALE_ID='SA002';
--
SELECT PD.*
FROM TBL_PAYMENT_DETAIL PD
JOIN TBL_PAYMENT P
ON PD.PAY_DETAIL_ID=P.PAY_DETAIL_ID
WHERE P.SALE_ID='SA002';
-- 판매 상세에 환
SELECT *
FROM TBL_SALE_DETAIL
WHERE SALE_ID='SA002'
ORDER BY SALE_DETAIL_ID;
--상품번호1,3,9 현재재고 35,18,48
SELECT *
FROM TBL_STOCK
WHERE PRODUCT_CODE IN
(
    SELECT PRODUCT_CODE
    FROM TBL_SALE_DETAIL
    WHERE SALE_ID='SA002'
);
-- 재고상세에 비고
SELECT *
FROM TBL_STOCK_DETAIL
WHERE PRODUCT_CODE IN
(
    SELECT PRODUCT_CODE
    FROM TBL_SALE_DETAIL
    WHERE SALE_ID='SA002'
)
ORDER BY STOCK_DETAIL_CODE;
-- 프로시져 실행
EXEC UP_REFUND('SA002');
-- 재실행 (사용자 예외처리 검증)
BEGIN
    UP_REFUND('SA002');
END;
/

--
show errors;
--
SELECT LINE,
       POSITION,
       TEXT
FROM USER_ERRORS
WHERE NAME = 'UP_REFUND'
ORDER BY SEQUENCE;

---------------------------------------------------------------------
프로시져 구조
UP_RECEIPT

↓

PAY_STATUS 조회

↓

IF 완료

THEN

"구매영수증"

ELSE

"환불영수증"

↓

CURSOR 상품조회

↓

FOR LOOP

↓

CURSOR 결제조회

↓

FOR LOOP

↓

DBMS_OUTPUT
/

TBL_PAYMENT 판단용
PAY_STATUS 완료 OR 환불

TBL_SALE_DETAIL 상품출력
( PRODUCT_CODE , QTY ,PRICE ,DISCOUNT_AMT ,STATUS )

TBL_PAYMENT_DETAIL 결제방법 출력
( PAY_METHOD , AMT )

환불시 환불프로시져로
SALE_DETAIL ,QTY ,PRICE,DISCOUNT 전부 음수로 출력.

첫번째 커서 상품명을 출력하기위해 상품테이블 조인, 한 판매에 여러상품있음.
두번째 커서 복합결제를 지원. 현금, 신용카드 결제금액 각각 출력 및 확인.
커서를 활용하면 결제영수증(양수로 상품금액들)이 환불영수증에도 같이 붙어서나와서
구분하는 의미를 위해 커서를 지우고 FOR SELECT 활용.
------------------------------------------------------------------
EXEC UP_RECEIPT('SA001');
EXEC UP_RECEIPT('SA002');

SELECT * FROM TBL_SALE_DETAIL;