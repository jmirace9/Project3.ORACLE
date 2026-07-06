
CREATE OR REPLACE PROCEDURE UP_RECEIPT
(
    P_SALE_ID IN TBL_SALE.SALE_ID%TYPE
)
IS

/******************************************************
    [1] 변수 선언
******************************************************/

-- 판매상태
V_PAY_STATUS TBL_PAYMENT.PAY_STATUS%TYPE;

-- 총수량
V_TOTAL_QTY TBL_SALE.TOTAL_QTY%TYPE;

-- 총금액
V_TOTAL_AMT TBL_SALE.TOTAL_AMT%TYPE;

-- 영수증출력시간 
V_NOW VARCHAR2(30);

-- 영수증 합계 출력용
V_TOTAL_DISCOUNT TBL_PAYMENT_DETAIL.TOTAL_DISCOUNT%TYPE;
V_USED_POINT TBL_PAYMENT_DETAIL.USED_POINT%TYPE;
V_PAYMENT_TOTAL NUMBER := 0;

BEGIN

    /******************************************************
    [3] 판매 정보 조회
******************************************************/

SELECT
       PAY_STATUS
INTO
       V_PAY_STATUS
FROM
(
    SELECT PAY_STATUS
    FROM TBL_PAYMENT
    WHERE SALE_ID = P_SALE_ID
    ORDER BY PAY_DETAIL_ID DESC
)
WHERE ROWNUM = 1;

V_NOW := TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS');

SELECT
       SUM(ABS(QTY)),
       SUM(ABS(QTY * PRICE))
INTO
       V_TOTAL_QTY,
       V_TOTAL_AMT
FROM TBL_SALE_DETAIL
WHERE SALE_ID = P_SALE_ID
AND STATUS = V_PAY_STATUS;

/******************************************************
    [3-1] 할인 / 포인트 조회
******************************************************/

SELECT
       TOTAL_DISCOUNT,
       USED_POINT
INTO
       V_TOTAL_DISCOUNT,
       V_USED_POINT
FROM
(
    SELECT PD.*
    FROM TBL_PAYMENT_DETAIL PD
    JOIN TBL_PAYMENT P
      ON PD.PAY_DETAIL_ID = P.PAY_DETAIL_ID
    WHERE P.SALE_ID = P_SALE_ID
      AND P.PAY_STATUS = V_PAY_STATUS
)
WHERE ROWNUM = 1;

-- 최종결제금액 불러오기
SELECT NVL(SUM(PD.AMT), 0)
INTO V_PAYMENT_TOTAL
FROM TBL_PAYMENT_DETAIL PD
JOIN TBL_PAYMENT P
  ON PD.PAY_DETAIL_ID = P.PAY_DETAIL_ID
WHERE P.SALE_ID = P_SALE_ID
  AND P.PAY_STATUS = V_PAY_STATUS;

/******************************************************
    [4] 영수증 헤더 출력
******************************************************/

DBMS_OUTPUT.PUT_LINE('=================================================');

IF V_PAY_STATUS = '완료' THEN
    DBMS_OUTPUT.PUT_LINE('                 [ 구매 영수증 ]');
ELSE
    DBMS_OUTPUT.PUT_LINE('                 [ 환불 영수증 ]');
END IF;

DBMS_OUTPUT.PUT_LINE('=================================================');

DBMS_OUTPUT.PUT_LINE('판매번호 : ' || P_SALE_ID);

DBMS_OUTPUT.PUT_LINE('판매상태 : ' || V_PAY_STATUS);

DBMS_OUTPUT.PUT_LINE('출력일시 : ' || V_NOW);

DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');

DBMS_OUTPUT.PUT_LINE(
    RPAD('상품명',20) ||
    LPAD('수량',8) ||
    LPAD('금액',12)
);

DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');

/******************************************************
    [5] 판매 상품 출력
******************************************************/

FOR REC_SALE_DETAIL IN
(
    SELECT
           SD.PRODUCT_CODE,
           P.PRODUCT_NAME,
           SD.QTY,
           SD.PRICE,
           SD.DISCOUNT_AMT,
           SD.STATUS
    FROM TBL_SALE_DETAIL SD
    JOIN TBL_PRODUCT P
      ON SD.PRODUCT_CODE = P.PRODUCT_CODE
    WHERE SD.SALE_ID = P_SALE_ID
      AND SD.STATUS = V_PAY_STATUS
    ORDER BY SD.SALE_DETAIL_ID
)
LOOP

    DBMS_OUTPUT.PUT_LINE
    (
        RPAD(REC_SALE_DETAIL.PRODUCT_NAME,20) ||
        LPAD(ABS(REC_SALE_DETAIL.QTY),8) ||
        LPAD
(
    TO_CHAR
    (
        ABS(REC_SALE_DETAIL.QTY * REC_SALE_DETAIL.PRICE),
        '999,999,999'
    ),
    12
)
    );

END LOOP;


DBMS_OUTPUT.PUT_LINE
(
    '-------------------------------------------------'
);

/******************************************************
    [6] 결제 내역 출력
******************************************************/

DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE('============== 결제 내역 ==============');

FOR REC_PAYMENT IN
(
    SELECT
           PD.PAY_METHOD,
           PD.AMT
    FROM TBL_PAYMENT_DETAIL PD
    JOIN TBL_PAYMENT P
      ON PD.PAY_DETAIL_ID = P.PAY_DETAIL_ID
    WHERE P.SALE_ID = P_SALE_ID
      AND P.PAY_STATUS = V_PAY_STATUS
    ORDER BY PD.PAY_DETAIL_NUMBER
)
LOOP

    DBMS_OUTPUT.PUT_LINE
    (
        RPAD(REC_PAYMENT.PAY_METHOD,20) ||
        LPAD
        (
            TO_CHAR
            (
                REC_PAYMENT.AMT,
                '999,999,999'
            ),
            15
        )
    );

END LOOP;

DBMS_OUTPUT.PUT_LINE('-----------------------------------------');

/******************************************************
    [7] 합계 출력
******************************************************/

DBMS_OUTPUT.PUT_LINE('');

DBMS_OUTPUT.PUT_LINE('=========================================');

DBMS_OUTPUT.PUT_LINE
(
    RPAD('상품금액',20) ||
    LPAD(TO_CHAR(V_TOTAL_AMT,'999,999,999'),15)
);

DBMS_OUTPUT.PUT_LINE
(
    RPAD('할인금액',20) ||
    LPAD(TO_CHAR(V_TOTAL_DISCOUNT,'999,999,999'),15)
);

DBMS_OUTPUT.PUT_LINE
(
    RPAD('사용포인트',20) ||
    LPAD(TO_CHAR(V_USED_POINT,'999,999,999'),15)
);

DBMS_OUTPUT.PUT_LINE
(
    RPAD('최종결제금액',20) ||
    LPAD(TO_CHAR(V_PAYMENT_TOTAL,'999,999,999'),15)
);

DBMS_OUTPUT.PUT_LINE('=========================================');

IF V_PAY_STATUS = '환불' THEN
    DBMS_OUTPUT.PUT_LINE('        환불이 정상 처리되었습니다.');
ELSE
    DBMS_OUTPUT.PUT_LINE('         구매해 주셔서 감사합니다.');
END IF;

DBMS_OUTPUT.PUT_LINE('');

DBMS_OUTPUT.PUT_LINE('        Oracle DB Project');
DBMS_OUTPUT.PUT_LINE('         SS25 POS System');
DBMS_OUTPUT.PUT_LINE('');
DBMS_OUTPUT.PUT_LINE('         Developed by Team SS25');
DBMS_OUTPUT.PUT_LINE('         Powered by Oracle PL/SQL');
DBMS_OUTPUT.PUT_LINE('            감사합니다.');
DBMS_OUTPUT.PUT_LINE('=========================================');

/******************************************************
    [8] 예외 처리
******************************************************/
EXCEPTION

    WHEN NO_DATA_FOUND THEN

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=========================================');
        DBMS_OUTPUT.PUT_LINE('해당 판매번호를 찾을 수 없습니다.');
        DBMS_OUTPUT.PUT_LINE('=========================================');

    WHEN OTHERS THEN

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=========================================');
        DBMS_OUTPUT.PUT_LINE('영수증 출력 중 오류가 발생했습니다.');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        DBMS_OUTPUT.PUT_LINE('=========================================');

END UP_RECEIPT;
/







