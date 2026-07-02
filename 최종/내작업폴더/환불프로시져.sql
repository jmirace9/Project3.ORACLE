/*
==========================================================
 Procedure Name : UP_REFUND
 Description    : 상품 환불 처리 프로시저
 Author         : 조지훈
 Date           : 2026-07-01
==========================================================

기능

1. 중복 환불 여부 확인
2. PAYMENT 환불내역 등록
3. PAYMENT_DETAIL 환불내역 등록
4. SALE_DETAIL 환불내역 등록
5. STOCK 재고 복구
6. STOCK_DETAIL 입고이력 등록

예외처리

- 이미 환불된 판매건은 환불 불가
==========================================================
*/

CREATE OR REPLACE PROCEDURE UP_REFUND
(
    P_SALE_ID      IN TBL_SALE.SALE_ID%TYPE
)
IS
    /******************************************************
        [1] 변수 선언
    ******************************************************/

-- 중복 환불 확인
V_REFUND_COUNT NUMBER := 0;

-- 생성될 PK
V_PAYMENT_ID         TBL_PAYMENT.PAY_DETAIL_ID%TYPE;
V_PAYMENT_DETAIL_ID  TBL_PAYMENT_DETAIL.PAY_DETAIL_NUMBER%TYPE;
V_SALE_DETAIL_ID     TBL_SALE_DETAIL.SALE_DETAIL_ID%TYPE;
V_STOCK_DETAIL_ID    TBL_STOCK_DETAIL.STOCK_DETAIL_CODE%TYPE;
V_EXPIRY_DATE TBL_STOCK_DETAIL.EXPIRY_DATE%TYPE;
V_STAFF_ID TBL_STAFF.STAFF_ID%TYPE;


V_STOCK TBL_STOCK%ROWTYPE;
    
    /******************************************************
      [2]  판매상세 조회 CURSOR
    ******************************************************/

    CURSOR CUR_SALE_DETAIL
IS
SELECT *
FROM TBL_SALE_DETAIL
WHERE SALE_ID = P_SALE_ID;

/******************************************************
    [2-1] 결제상세 조회 CURSOR
******************************************************/

CURSOR CUR_PAYMENT_DETAIL
IS
SELECT PD.*
FROM TBL_PAYMENT_DETAIL PD
JOIN TBL_PAYMENT P
ON PD.PAY_DETAIL_ID = P.PAY_DETAIL_ID
WHERE P.SALE_ID = P_SALE_ID
AND P.PAY_STATUS = '완료';

BEGIN

    /******************************************************
      [3]  중복 환불 여부 확인
    ******************************************************/

    SELECT COUNT(*)
      INTO V_REFUND_COUNT
      FROM TBL_PAYMENT
     WHERE SALE_ID = P_SALE_ID
       AND PAY_STATUS = '환불';

    IF V_REFUND_COUNT > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            '이미 환불된 판매입니다.'
        );
    END IF;
/******************************************************
    [3-1] 판매 직원 조회
******************************************************/

SELECT STAFF_ID
INTO V_STAFF_ID
FROM TBL_SALE
WHERE SALE_ID = P_SALE_ID;
    /******************************************************
     [4]   PAYMENT 환불내역 등록
    ******************************************************/
    
    --   환불 PAYMENT PK 생성
    V_PAYMENT_ID := UF_NEXT_PAYMENT();
    
    INSERT INTO TBL_PAYMENT
    (
        PAY_DETAIL_ID,
        SALE_ID,
        PAY_STATUS
    )
    VALUES
    (
        V_PAYMENT_ID,
        P_SALE_ID,
        '환불'
    );

  /******************************************************
    [5] PAYMENT_DETAIL 환불 등록
******************************************************/

FOR REC_PAYMENT IN CUR_PAYMENT_DETAIL LOOP

    -- 환불 결제상세 PK 생성
    V_PAYMENT_DETAIL_ID := UF_NEXT_PAYMENT_DETAIL();

    INSERT INTO TBL_PAYMENT_DETAIL
    (
        PAY_DETAIL_NUMBER,
        TOTAL_AMT,
        TOTAL_DISCOUNT,
        USED_POINT,
        AMT,
        PAY_DETAIL_ID,
        PAY_METHOD
    )
    VALUES
    (
        V_PAYMENT_DETAIL_ID,
        -REC_PAYMENT.TOTAL_AMT,
        -REC_PAYMENT.TOTAL_DISCOUNT,
        -REC_PAYMENT.USED_POINT,
        -REC_PAYMENT.AMT,
        V_PAYMENT_ID,
        REC_PAYMENT.PAY_METHOD
    );

END LOOP;
    /******************************************************
        [6] SALE_DETAIL 환불 로그 등록
    ******************************************************/

    FOR REC_SALE_DETAIL IN CUR_SALE_DETAIL LOOP

        -- 환불 판매상세번호 생성
        V_SALE_DETAIL_ID := UF_NEXT_SALE_DETAIL();

        INSERT INTO TBL_SALE_DETAIL
        (
            SALE_DETAIL_ID,
            PRODUCT_CODE,
            SALE_ID,
            QTY,
            PRICE,
            DISCOUNT_AMT,
            STATUS
        )
        VALUES
        (
            V_SALE_DETAIL_ID,
            REC_SALE_DETAIL.PRODUCT_CODE,
            P_SALE_ID,
            -REC_SALE_DETAIL.QTY,
            -REC_SALE_DETAIL.PRICE,
            -REC_SALE_DETAIL.DISCOUNT_AMT,
            '환불'
        );
        
    /******************************************************
        [7] 재고 복구
    ******************************************************/

UPDATE TBL_STOCK
SET STOCK_QTY = STOCK_QTY + REC_SALE_DETAIL.QTY
WHERE PRODUCT_CODE = REC_SALE_DETAIL.PRODUCT_CODE;
        
    SELECT *
    INTO V_STOCK
    FROM TBL_STOCK
    WHERE PRODUCT_CODE = REC_SALE_DETAIL.PRODUCT_CODE;

SELECT MAX(EXPIRY_DATE)
INTO V_EXPIRY_DATE
FROM TBL_STOCK_DETAIL
WHERE PRODUCT_CODE = REC_SALE_DETAIL.PRODUCT_CODE;

V_STOCK_DETAIL_ID := UF_NEXT_STOCK_DETAIL();

INSERT INTO TBL_STOCK_DETAIL
(
    STOCK_DETAIL_CODE,
    STOCK_DATE,
    STOCK_TYPE,
    QTY,
    BIGO,
    EXPIRY_DATE,
    STAFF_ID,
    STOCK_SEQ,
    PRODUCT_CODE
)
VALUES
(
    V_STOCK_DETAIL_ID,
    SYSDATE,
    '입고',
    REC_SALE_DETAIL.QTY,
    '환불입고',
    V_EXPIRY_DATE,
    (
        SELECT STAFF_ID
        FROM TBL_SALE
        WHERE SALE_ID = P_SALE_ID
    ),
    V_STOCK.STOCK_SEQ,
    REC_SALE_DETAIL.PRODUCT_CODE
);

    END LOOP;
    /******************************************************
        [9] 트랜잭션 완료
    ******************************************************/
    COMMIT;
    /******************************************************
        [10] 예외 처리
    ******************************************************/
EXCEPTION

    -- 이미 환불된 판매
    WHEN OTHERS THEN

        ROLLBACK;

        RAISE_APPLICATION_ERROR
        (
            -20002,
            '환불 처리 중 오류가 발생했습니다.'
        );

END UP_REFUND;
/
show errors;
DESC TBL_STOCK_DETAIL;
DESC TBL_STOCK;
DESC TBL_PAYMENT;
DESC TBL_PAYMENT_DETAIL;
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME LIKE 'UF%';
DESC TBL_PRODUCT;
DESC TBL_DISCARD;
SELECT OBJECT_NAME, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME='UP_REFUND';
