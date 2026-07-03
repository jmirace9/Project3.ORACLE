---류호훈님이 작성
create or replace TRIGGER af_sale_sm
AFTER INSERT ON tbl_payment_detail
FOR EACH ROW
BEGIN
   IF :new.pay_method = '현금' THEN
        UPDATE tbl_settlement
        SET real_cash = real_cash + :NEW.total_amt
        WHERE TRUNC(settle_date) = TRUNC(SYSDATE);
    END IF;
END;

-- 문규리
---시퀀스 생성
DROP SEQUENCE seq_product;
DROP SEQUENCE seq_order;
DROP SEQUENCE seq_order_detail;

DECLARE
    v_max_product       NUMBER;
    v_max_order         NUMBER;
    v_max_order_detail  NUMBER;
BEGIN
   
SELECT NVL(MAX(TO_NUMBER(SUBSTR(product_code, 3))), 100) + 1 
INTO v_max_product FROM tbl_product;
    
    
SELECT NVL(MAX(TO_NUMBER(SUBSTR(order_id, 3))), 60) + 1 
INTO v_max_order FROM tbl_order;
    
    
SELECT NVL(MAX(TO_NUMBER(SUBSTR(order_detail_id, 3))), 160) + 1 
INTO v_max_order_detail FROM tbl_order_detail;

    
EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_product START WITH ' || v_max_product || ' INCREMENT BY 1 NOCACHE NOCYCLE';
EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_order START WITH ' || v_max_order || ' INCREMENT BY 1 NOCACHE NOCYCLE';
EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_order_detail START WITH ' || v_max_order_detail || ' INCREMENT BY 1 NOCACHE NOCYCLE';
END;


select * from tbl_product;
delete from tbl_product where product_code > 'PR100';
------------------------------------------
-- 신상품 등록!
------------------------------------------
CREATE OR REPLACE PROCEDURE proc_register_product
(
    p_vendor_code     IN VARCHAR2,
    p_scategory_code  IN VARCHAR2,
    p_product_name    IN VARCHAR2,
    p_barcode         IN VARCHAR2,
    p_price           IN NUMBER
)
IS
    v_cnt NUMBER;
    v_product_code NUMBER;
BEGIN
    v_product_code := seq_product.NEXTVAL;

    -- 바코드 중복 체크
    SELECT COUNT(*) INTO v_cnt FROM tbl_product WHERE barcode = p_barcode;

    IF v_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, '바코드 중복');
    END IF;

    -- 상품명 중복 체크
    SELECT COUNT(*) INTO v_cnt FROM tbl_product WHERE product_name = p_product_name;

    IF v_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, '상품명 중복');
    END IF;

    INSERT INTO tbl_product
    VALUES
    (
        'PR' || v_product_code,
        p_vendor_code,
        p_scategory_code,
        NULL,
        p_product_name,
        p_barcode,
        p_price
    );

    DBMS_OUTPUT.PUT_LINE(
        '새 상품이 등록되었습니다 : ' || p_product_name ||
        ' / 상품코드 : PR' || v_product_code ||
        ' / 유통업체 : ' || p_vendor_code ||
        ' / 소비자가 : ' || p_price
    );
END;
/



------------------------------------------
-- 발주등록!
------------------------------------------
CREATE OR REPLACE PROCEDURE proc_create_order
(
    p_order_date  IN DATE,
    p_staff_id    IN VARCHAR2,
    p_vendor_code IN VARCHAR2,
    p_order_id    OUT VARCHAR2
)
IS
    v_order_id VARCHAR2(20);
BEGIN
    v_order_id := 'OR' || seq_order.NEXTVAL;

    INSERT INTO tbl_order
    VALUES (
        v_order_id,
        p_order_date,
        '진행중',
        p_staff_id,
        p_vendor_code
    );

    p_order_id := v_order_id;
    DBMS_OUTPUT.put_line('발주번호: ' || v_order_id || '----------');
END;
/


------------------------------------------
-- 발주목록!
------------------------------------------
CREATE OR REPLACE PROCEDURE proc_add_order_detail
(
    p_order_id        IN VARCHAR2,
    p_product_code    IN VARCHAR2,
    p_price           IN NUMBER,
    p_qty             IN NUMBER
)
IS
    v_cnt NUMBER;
    v_product_name tbl_product.product_name%TYPE;
    v_od_id tbl_order_detail.order_detail_id%TYPE;
BEGIN
    -- 상품 존재 체크
    SELECT COUNT(*) INTO v_cnt FROM tbl_product WHERE product_code = p_product_code;

    IF v_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, '존재하지 않는 상품입니다. 발주 중단');
    END IF;
    
    v_od_id := 'OD' || seq_order_detail.NEXTVAL;
    
    -- 발주상세 insert
    INSERT INTO tbl_order_detail
    VALUES (
        v_od_id,
        p_order_id,
        p_product_code,
        p_price,
        p_qty
    );
    
    SELECT product_name INTO v_product_name FROM tbl_product WHERE product_code = p_product_code;
    
    DBMS_OUTPUT.put_line('발주상세번호: ' || v_od_id || ' 상품: ' || v_product_name || ' / 발주단가: ' || p_price || ' 발주수량: ' || p_qty);
END;



-- 1. 새 상품 등록 시연
SET SERVEROUTPUT ON;
BEGIN
    proc_register_product(
        'VE04',
        'SC17',
        '요플레 c',
        '880100000103',
        1500
    );
    proc_register_product(
        'VE04',
        'SC17',
        '요플레 D',
        '880100000104',
        1500
    );
END;

select * from tbl_product
order by product_code DESC
fetch first 10 rows only;

delete from tbl_product where product_code > 'PR100';
commit;

select * from tbl_order_detail;
-- 2. 발주 신청 시연
DECLARE
    v_order_id VARCHAR2(20);
BEGIN
    proc_create_order(
        SYSDATE,
        'ST04',
        'VE04',
        v_order_id
    );

    proc_add_order_detail(
        v_order_id,
        'PR101',
        1000,
        10
    );

    proc_add_order_detail(
        v_order_id,
        'PR102',
        1000,
        20
    );

    proc_add_order_detail(
        v_order_id,
        'PR090',
        1000,
        30
    );
END;

select * from tbl_order;

ROLLBACK;


select * from tbl_order;
---테이블확인용
select * from tbl_product
order by product_code;
select * from tbl_order;

select * from tbl_order_detail
order by order_detail_id;




DROP SEQUENCE seq_sale;
DROP SEQUENCE seq_sale_detail;
DROP SEQUENCE seq_payment;
DROP SEQUENCE seq_payment_detail;
DROP SEQUENCE seq_stock_detail;

--시퀀스 생성----
DECLARE
    v_max_sale           NUMBER;
    v_max_sale_detail    NUMBER;
    v_max_payment        NUMBER;
    v_max_payment_detail NUMBER;
    v_max_stock_detail   NUMBER;
BEGIN
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(sale_id, 3))), 70) + 1 
    INTO v_max_sale FROM tbl_sale;
    
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(sale_detail_id, 4))), 200) + 1 
    INTO v_max_sale_detail FROM tbl_sale_detail;
    
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(pay_detail_id, 3))), 70) + 1 
    INTO v_max_payment FROM tbl_payment;
    
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(pay_detail_number, 4))), 100) + 1 
    INTO v_max_payment_detail FROM tbl_payment_detail;
    
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(stock_detail_code, 3))), 200) + 1 
    INTO v_max_stock_detail FROM tbl_stock_detail;

    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_sale START WITH ' || v_max_sale || ' INCREMENT BY 1 NOCACHE NOCYCLE';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_sale_detail START WITH ' || v_max_sale_detail || ' INCREMENT BY 1 NOCACHE NOCYCLE';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_payment START WITH ' || v_max_payment || ' INCREMENT BY 1 NOCACHE NOCYCLE';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_payment_detail START WITH ' || v_max_payment_detail || ' INCREMENT BY 1 NOCACHE NOCYCLE';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_stock_detail START WITH ' || v_max_stock_detail || ' INCREMENT BY 1 NOCACHE NOCYCLE';
END;



---판매 시작-----
CREATE OR REPLACE PROCEDURE up_sale_start
(   p_sale_id      OUT TBL_SALE.sale_id%TYPE,
    p_staff_id     IN TBL_SALE.staff_id%TYPE,
    p_customer_id  IN TBL_SALE.customer_id%TYPE
)
IS
BEGIN
    p_sale_id := 'SA' || LPAD(seq_sale.NEXTVAL, 3, '0');

    INSERT INTO TBL_SALE
    (
        sale_id,
        staff_id,
        customer_id,
        sale_date,
        total_amt,
        total_qty
    )
    VALUES
    (
        p_sale_id,
        p_staff_id,
        p_customer_id,
        SYSDATE,
        0,
        0
    );
END;



---판매 상세 기록---
CREATE OR REPLACE PROCEDURE up_sale_detail
(
    p_sale_id      IN TBL_SALE.sale_id%TYPE,
    p_product_code IN TBL_PRODUCT.product_code%TYPE,
    p_qty          IN NUMBER
)
IS
    v_price         TBL_PRODUCT.price%TYPE;
    v_event_name    TBL_EVENT_TYPE.event_name%TYPE;
    v_discount      TBL_EVENT_TYPE.discount_amt%TYPE;
    v_event_status  TBL_EVENT.event_status%TYPE;
    v_stock_qty     TBL_STOCK.stock_qty%TYPE; 
    v_discount_amt  NUMBER := 0;
    v_product_name  TBL_PRODUCT.product_name%TYPE;
    v_final_qty     NUMBER := p_qty; 
BEGIN
    SELECT  p.price,
            p.product_name,
            NVL(et.event_name,'없음'),
            NVL(et.discount_amt,0),
            NVL(e.event_status,'종료')
    INTO    v_price,
            v_product_name,
            v_event_name,
            v_discount,
            v_event_status
    FROM tbl_product p
         LEFT JOIN tbl_event e    ON p.event_code = e.event_code
         LEFT JOIN tbl_event_type et ON e.event_code = et.event_code
    WHERE p.product_code = p_product_code;

    IF v_event_status = '진행중' THEN
        IF v_event_name = '1+1' THEN
            IF MOD(p_qty, 2) = 1 THEN
                v_final_qty := p_qty + 1;
            END IF;
        ELSIF v_event_name = '2+1' THEN
            IF MOD(p_qty, 3) = 2 THEN
                v_final_qty := p_qty + 1;
            END IF;
        END IF;
    ELSE
        v_event_name := '없음';
    END IF;

    SELECT NVL(stock_qty, 0)
    INTO v_stock_qty
    FROM tbl_stock
    WHERE product_code = p_product_code;

    IF v_stock_qty < v_final_qty THEN
        RAISE_APPLICATION_ERROR(-20002, '행사 증정품을 포함한 재고가 부족합니다. (현재 재고: ' || v_stock_qty || '개 / 필요 수량: ' || v_final_qty || '개)');
    END IF;

    IF v_event_status = '진행중' THEN
        IF v_event_name = '1+1' THEN
            v_discount_amt := FLOOR(v_final_qty / 2) * v_price;
        ELSIF v_event_name = '2+1' THEN
            v_discount_amt := FLOOR(v_final_qty / 3) * v_price;
        ELSE
            v_discount_amt := (v_price * v_final_qty) * (v_discount / 100);
        END IF;
    END IF;

    INSERT INTO tbl_sale_detail
    (
        sale_detail_id, product_code, sale_id, qty, price, discount_amt, status
    )
    VALUES
    (
        'SAD' || LPAD(seq_sale_detail.NEXTVAL,3,'0'),
        p_product_code, p_sale_id, v_final_qty, v_price, v_discount_amt, '대기'
    );

    UPDATE tbl_sale
    SET total_qty = (SELECT SUM(qty) FROM tbl_sale_detail WHERE sale_id = p_sale_id)
    WHERE sale_id = p_sale_id;

    DBMS_OUTPUT.PUT_LINE(
        '상품코드: ' || p_product_code || 
        ', 상품명: ' || v_product_name || 
        ', 소비자가: ' || v_price || 
        ', 수량(증정포함): ' || v_final_qty || ' (기존: ' || p_qty || ')' ||
        ', 행사타입: ' || v_event_name
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('존재하지 않는 상품 또는 재고 정보가 등록되지 않은 상품입니다.');
    WHEN OTHERS THEN
        IF SQLCODE = -20002 THEN
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
        ELSE
            DBMS_OUTPUT.PUT_LINE('오류 발생: ' || SQLERRM);
        END IF;
END;

---결제 시행----
CREATE OR REPLACE PROCEDURE up_payment
(
    p_sale_id       IN TBL_SALE.sale_id%TYPE,          
    p_cash_amt      IN NUMBER DEFAULT 0,               
    p_used_point    IN NUMBER DEFAULT 0                
)
IS
    v_customer_id   TBL_CUSTOMER.customer_id%TYPE;
    v_total_amt      NUMBER := 0; 
    v_total_discount NUMBER := 0; 
    v_actual_price  NUMBER := 0; 
    v_pay_amt       NUMBER := 0; 
    v_earn_point    NUMBER := 0; 
    v_current_point NUMBER := 0; 
    v_calc_card     NUMBER := 0; 
    v_pay_id        TBL_PAYMENT.pay_detail_id%TYPE;
BEGIN
    SELECT customer_id INTO v_customer_id FROM tbl_sale WHERE sale_id = p_sale_id;

    SELECT NVL(SUM(price * qty), 0), NVL(SUM(discount_amt), 0)
    INTO v_total_amt, v_total_discount
    FROM tbl_sale_detail
    WHERE sale_id = p_sale_id;

    v_actual_price := v_total_amt - v_total_discount;
    
    IF v_customer_id = 'CU001' THEN 
        v_pay_amt    := v_actual_price; 
        v_earn_point := 0;              
    ELSE
        v_pay_amt    := v_actual_price - p_used_point;
        v_earn_point := TRUNC(v_pay_amt * 0.02, -1); 

        IF p_used_point > 0 THEN
            SELECT point INTO v_current_point FROM tbl_customer WHERE customer_id = v_customer_id;
            IF v_current_point < p_used_point THEN
                RAISE_APPLICATION_ERROR(-20001, '보유 포인트가 부족합니다.');
            END IF;
        END IF;
    END IF;

    IF p_cash_amt >= v_pay_amt THEN
        v_calc_card := 0; 
    ELSE
        v_calc_card := v_pay_amt - p_cash_amt;
    END IF;

    UPDATE tbl_sale SET total_amt = v_total_amt WHERE sale_id = p_sale_id;
    
    v_pay_id := 'PA' || LPAD(seq_payment.NEXTVAL, 3, '0');
    INSERT INTO tbl_payment (pay_detail_id, sale_id, pay_status) VALUES (v_pay_id, p_sale_id, '대기');

    IF p_cash_amt > 0 THEN
        INSERT INTO tbl_payment_detail (
            pay_detail_number, total_amt, total_discount, used_point, amt, pay_detail_id, pay_method
        ) VALUES (
            'PAD' || LPAD(seq_payment_detail.NEXTVAL, 3, '0'),
            v_total_amt, v_total_discount, 
            CASE WHEN v_customer_id = 'CU001' THEN 0 ELSE p_used_point END,
            CASE WHEN p_cash_amt >= v_pay_amt THEN v_pay_amt ELSE p_cash_amt END, 
            v_pay_id, '현금'
        );
    END IF;

    IF v_calc_card > 0 THEN
        INSERT INTO tbl_payment_detail (
            pay_detail_number, 
            total_amt,        
            total_discount,   
            used_point,       
            amt, 
            pay_detail_id, 
            pay_method
        ) VALUES (
            'PAD' || LPAD(seq_payment_detail.NEXTVAL, 3, '0'),
            v_total_amt, 
            v_total_discount, 
            CASE WHEN v_customer_id = 'CU001' THEN 0 ELSE p_used_point END, 
            v_calc_card, 
            v_pay_id, 
            '카드'
        );
    END IF;

    IF v_customer_id != 'CU001' THEN
        UPDATE tbl_customer SET point = point - p_used_point + v_earn_point WHERE customer_id = v_customer_id;
    END IF;

    UPDATE tbl_sale_detail SET status = '판매완료' WHERE sale_id = p_sale_id;

    UPDATE tbl_payment SET pay_status = '완료' WHERE pay_detail_id = v_pay_id;

    DBMS_OUTPUT.PUT_LINE('결제 완료. [총액: ' || v_pay_amt || '원] -> 현금: ' || (v_pay_amt - v_calc_card) || '원 / 카드(자동계산): ' || v_calc_card || '원');
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;

select * from tbl_sale_detail;

--트리거: 결제 완료시 재고, 재고상세 변경 
CREATE OR REPLACE TRIGGER trg_payment_complete
AFTER UPDATE OF pay_status ON TBL_PAYMENT
FOR EACH ROW
WHEN (NEW.pay_status = '완료')
DECLARE
    v_staff_id TBL_SALE.staff_id%TYPE;
    v_stock_seq TBL_STOCK.stock_seq%TYPE;
BEGIN
    SELECT staff_id INTO v_staff_id
    FROM tbl_sale
    WHERE sale_id = :NEW.sale_id;

    FOR r IN (SELECT product_code, qty FROM tbl_sale_detail WHERE sale_id = :NEW.sale_id) LOOP
        
        SELECT stock_seq INTO v_stock_seq 
        FROM tbl_stock 
        WHERE product_code = r.product_code;

        UPDATE tbl_stock
        SET stock_qty = stock_qty - r.qty
        WHERE product_code = r.product_code;

        INSERT INTO tbl_stock_detail (
            stock_detail_code, stock_date, stock_type, qty, bigo, expiry_date, staff_id, stock_seq, product_code
        ) VALUES (
            'SD' || LPAD(seq_stock_detail.NEXTVAL, 3, '0'),
            SYSDATE,
            '출고',
            r.qty,
            '판매출고',
            NULL,
            v_staff_id,
            v_stock_seq,
            r.product_code
        );
    END LOOP;
END;


SET SERVEROUTPUT ON;
DECLARE
    v_generated_id TBL_SALE.sale_id%TYPE;
BEGIN
    up_sale_start(v_generated_id, 'ST01', 'CU003');   
    up_sale_detail(v_generated_id, 'PR047', 2);
    up_payment(
        p_sale_id    => v_generated_id, 
        p_cash_amt   => 6600, 
        p_used_point => 100
    );
    DBMS_OUTPUT.PUT_LINE('판매번호: ' || v_generated_id);
END;
ROLLBACK;

select * from tbl_sale_Detail;


-------------테이블변경확인용
SELECT * FROM tbl_product;
SELECT * FROM tbl_sale;
SELECT * FROM tbl_sale_detail;
SELECT * FROM tbl_payment;
SELECT * FROM tbl_payment_detail;
SELECT * FROM tbl_stock;
SELECT * FROM tbl_stock_detail;
SELECT * FROM tbl_customer;

SELECT 
    e.event_code        AS "이벤트 코드",
    e.event_status      AS "이벤트 상태",
    et.event_name       AS "이벤트 종류",  
    et.discount_amt     AS "할인율/금액",
    p.product_code      AS "상품 코드",
    p.product_name      AS "상품 이름",
    p.price             AS "원래 가격"
FROM tbl_product p
INNER JOIN tbl_event e 
   ON p.event_code = e.event_code
INNER JOIN tbl_event_type et 
   ON e.event_code = et.event_code
WHERE e.event_status = '진행중'
ORDER BY e.event_code, p.product_code;
-- 문규리 끝

-- 조지훈 시작


/*
    함수명 : UF_NEXT_PAYMENT
    작성자 : 조지훈
    기능
    - PAYMENT PK 생성
    - 현재 가장 큰 PAY_DETAIL_ID를 찾아 다음 번호를 반환한다.
    예)
    PA001
    PA002
    ...
*/

CREATE OR REPLACE FUNCTION UF_NEXT_PAYMENT
RETURN VARCHAR2
IS
    V_NEXT_NO NUMBER;
BEGIN

    SELECT NVL(MAX(TO_NUMBER(SUBSTR(PAY_DETAIL_ID,3))),0)+1
    INTO V_NEXT_NO
    FROM TBL_PAYMENT;

    RETURN 'PA' || LPAD(V_NEXT_NO,3,'0');

END;
/
/*
    PAYMENT_DETAIL PK 생성
*/

CREATE OR REPLACE FUNCTION UF_NEXT_PAYMENT_DETAIL
RETURN VARCHAR2
IS
    V_NEXT_NO NUMBER;
BEGIN

    SELECT NVL(MAX(TO_NUMBER(SUBSTR(PAY_DETAIL_NUMBER,4))),0)+1
    INTO V_NEXT_NO
    FROM TBL_PAYMENT_DETAIL;

    RETURN 'PAD' || LPAD(V_NEXT_NO,3,'0');

END;
/
/*
    SALE_DETAIL PK 생성
*/

CREATE OR REPLACE FUNCTION UF_NEXT_SALE_DETAIL
RETURN VARCHAR2
IS
    V_NEXT_NO NUMBER;
BEGIN

    SELECT NVL(MAX(TO_NUMBER(SUBSTR(SALE_DETAIL_ID,4))),0)+1
    INTO V_NEXT_NO
    FROM TBL_SALE_DETAIL;

    RETURN 'SAD' || LPAD(V_NEXT_NO,3,'0');

END;
/

/*
    STOCK_DETAIL PK 생성
*/

CREATE OR REPLACE FUNCTION UF_NEXT_STOCK_DETAIL
RETURN VARCHAR2
IS
    V_NEXT_NO NUMBER;
BEGIN

    SELECT NVL(MAX(TO_NUMBER(SUBSTR(STOCK_DETAIL_CODE,3))),0)+1
    INTO V_NEXT_NO
    FROM TBL_STOCK_DETAIL;

    RETURN 'SD' || LPAD(V_NEXT_NO,3,'0');

END;
/

--  환불(조지훈)
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

exec up_receipt('SA070');
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

-- 영수증(조지훈)

UP_RECEIPT 설계도

[1] 변수 선언

↓

[2] CURSOR 선언

↓

[3] 판매상태 조회

↓

[4] 영수증 제목 출력

↓

[5] 상품 출력

↓

[6] 결제내역 출력

↓

[7] 합계 출력

↓

[8] 예외처리

/*
=========================================================
    프로시저명 : UP_RECEIPT

    작성자 : 조지훈

    기능
    - 판매번호(SALE_ID)를 입력받아
      구매영수증 또는 환불영수증을 출력한다.

    사용법

    - BEGIN
        UP_RECEIPT('SA001');
    END;
    
    OR
    
    - EXEC UP_RECEIPT('SA001');

=========================================================
*/

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
       TOTAL_QTY,
       TOTAL_AMT
INTO
       V_TOTAL_QTY,
       V_TOTAL_AMT
FROM TBL_SALE
WHERE SALE_ID = P_SALE_ID;

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
        LPAD(TO_CHAR(REC_SALE_DETAIL.PRICE,'999,999,999'),12)
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

select * from tbl_sale_detail;
exec UP_RECEIPT('SA072');
exec up_refund('SA072');

select * from tbl_stock_detail;
-- 조지훈 끝








-- 정빈시작

--------------------------------------------------------------------------------
-- 새 상품을 발주 할 경우 상품테이블에서 먼저 상품을 insert 한 다음
-- 발주 테이블에서 insert 를 한다 이때 발주 상태는 대기중
-- 발주 상세 테이블에 발주를 넣은것을 insert 한다

-- 발주 테이블에서 발주 상세를 완료 라고 update 하면 트리거 발생
-- 재고 테이블에서 현재 수량이 발주를 넣은 수량만큼 증가
-- 재고 상세 테이블에서 처리일시, 입출고구분, 변동수량, 비고 유통기한 추가


-- 재고 새로운 수량 시 stock_seq 자동증가 sequence
DECLARE
    v_max NUMBER;
BEGIN
    SELECT NVL(MAX(stock_seq), 0) + 1 INTO v_max FROM tbl_stock;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_stock_seq START WITH ' || v_max || ' INCREMENT BY 1';
END;

-- stock_detail 테이블 pk 자동증가 sequence
DECLARE
    v_max NUMBER;
BEGIN
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(stock_detail_code, 3))), 0) + 1 
    INTO v_max 
    FROM tbl_stock_detail;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_stock_detail_code START WITH ' || v_max || ' INCREMENT BY 1';
END;

SELECT seq_stock_detail_code.CURRVAL
FROM dual;
select * from tbl_stock_detail;
DROP SEQUENCE SEQ_STOCK_DETAIL_CODE;

CREATE SEQUENCE SEQ_STOCK_DETAIL_CODE INCREMENT BY 1 START WITH 207 MAXVALUE 9999999999999999999999999999 MINVALUE 207 CACHE 20;


CREATE OR REPLACE TRIGGER ut_order_stock_in AFTER
UPDATE ON tbl_order
FOR EACH ROW
DECLARE
    v_stock_seq NUMBER;
    v_mcategory_code tbl_mcategory.mcategory_code%TYPE;
    v_expiry_date DATE;
    v_detail_cnt NUMBER;
BEGIN
    IF :OLD.order_status != '완료' AND :NEW.order_status = '완료' THEN
        
        SELECT COUNT(*) 
        INTO v_detail_cnt
        FROM tbl_order_detail
        WHERE order_id = :NEW.order_id;

        IF v_detail_cnt = 0 THEN
            RAISE_APPLICATION_ERROR(-20030, '발주 상세 내역이 없습니다. 빈 발주서는 완료할 수 없습니다.');
        END IF;
        
        FOR item IN(
            SELECT product_code, qty
            FROM tbl_order_detail
            WHERE order_id = :NEW.order_id
        )
        LOOP
            MERGE INTO tbl_stock t
            USING DUAL
                ON (t.product_code = item.product_code)
            WHEN MATCHED THEN
                UPDATE SET t.stock_qty = t.stock_qty + item.qty
            WHEN NOT MATCHED THEN
                INSERT (stock_seq, product_code, stock_qty)
                VALUES (seq_stock_seq.NEXTVAL, item.product_code, item.qty);
            
            -- 재고 순번 조회
            SELECT stock_seq INTO v_stock_seq
            FROM tbl_stock
            WHERE product_code = item.product_code;
            
            -- 상품의 중분류 조회
            SELECT m.mcategory_code INTO v_mcategory_code
            FROM tbl_product p
                JOIN tbl_scategory s ON p.scategory_code = s.scategory_code
                JOIN tbl_mcategory m ON s.mcategory_code = m.mcategory_code
            WHERE p.product_code = item.product_code;
            
            -- 중분류별 유통기한 계산
            v_expiry_date :=
                CASE v_mcategory_code
                    -- 과자 
                    WHEN 'MC01' THEN SYSDATE + 180
                    -- 음료
                    WHEN 'MC02' THEN SYSDATE + 300
                    -- 라면
                    WHEN 'MC03' THEN SYSDATE + 240
                    -- 유제품
                    WHEN 'MC04' THEN SYSDATE + 14
                    -- 냉동식품
                    WHEN 'MC05' THEN SYSDATE + 365
                    -- 세제, 욕실용품, 주방용품, 문구, 생활잡화
                    ELSE NULL
                END;
                
            -- 재고 상세 등록
            INSERT INTO tbl_stock_detail (
                stock_detail_code, 
                stock_date, 
                stock_type, 
                qty, 
                bigo, 
                expiry_date, 
                staff_id, 
                stock_seq, 
                product_code
            ) VALUES (
                    'SD' || seq_stock_detail_code.NEXTVAL,
                    SYSDATE,                               
                    '발주입고',
                    item.qty,
                    '발주번호: ' || :NEW.order_id || ' 입고완료',
                    v_expiry_date,  
                    :NEW.staff_id,
                    v_stock_seq,
                    item.product_code
            );
            END LOOP;
        END IF;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100, '데이터 처리 중 필수 정보(재고순번/분류 등)를 찾을 수 없습니다.'); 
END;


-- 폐기

-- 폐기 테이블, 폐기 상세 테이블 프로시저 생성
-- 각각 테이블 pk 시퀀스 필요
-- 폐기 테이블 pk 시퀀스
DECLARE
    v_max NUMBER;
BEGIN
    SELECT NVL(MAX(discard_id), 0) + 1 INTO v_max FROM tbl_discard;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_discard START WITH ' || v_max || ' INCREMENT BY 1';
END;

-- 폐기 상세 테이블 pk 시퀀스
DECLARE
    v_max NUMBER;
BEGIN
    SELECT NVL(MAX(TO_NUMBER(SUBSTR(discard_detail_code, 3))), 0) + 1 INTO v_max FROM tbl_discard_detail;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_discard_detail START WITH ' || v_max || ' INCREMENT BY 1';
END;

SELECT * FROM tbl_discard;

-- 폐기 테이블 프로시저
CREATE OR REPLACE PROCEDURE up_create_discard
(
    p_staff_id IN VARCHAR2,
    p_discard_id OUT NUMBER
)
IS
    v_staff_cnt NUMBER;
    v_discard_id NUMBER;
BEGIN
    
    SELECT COUNT(*)
    INTO v_staff_cnt
    FROM tbl_staff
    WHERE staff_id = p_staff_id;
    
    IF v_staff_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, '존재하지 않는 직원입니다.');
        RETURN;
    END IF;
    
    v_discard_id := seq_discard.NEXTVAL;
    
    INSERT INTO tbl_discard(discard_id, discard_date, staff_id)
    VALUES (v_discard_id, SYSDATE, p_staff_id);
    
    p_discard_id := v_discard_id;
    DBMS_OUTPUT.PUT_LINE('폐기번호: ' || v_discard_id || ' 생성완료');

END;

SELECT * FROM tbl_discard_detail;


-- 폐기 상세 (상품) 추가 프로시저
CREATE OR REPLACE PROCEDURE up_add_discard_detail
(
    p_discard_id   IN NUMBER,
    p_product_code IN VARCHAR2,
    p_discard_qty  IN NUMBER
)
IS
    v_detail_code VARCHAR2(30);
    v_stock_cnt   NUMBER;
    v_current_qty NUMBER;
    v_discard_cnt NUMBER;
BEGIN
    SELECT COUNT(*) 
    INTO v_stock_cnt
    FROM tbl_stock
    WHERE product_code = p_product_code;
    
    -- 폐기 수량 1개 이상인지 확인
    IF p_discard_qty <= 0 THEN
        RAISE_APPLICATION_ERROR(-20020, '폐기 수량은 1개 이상이어야 합니다.');
    END IF;
    
    -- 폐기 번호가 진짜 존재 하는지
    SELECT COUNT(*)
    INTO v_discard_cnt
    FROM tbl_discard
    WHERE discard_id = p_discard_id;
    
    IF v_discard_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20021, '존재하지 않는 폐기 영수증 번호입니다.');
    END IF;
    
    -- 폐기 상품 존재 여부 확인
    IF v_stock_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, '창고에 존재하지 않는 상품입니다. (폐기 불가)');
    END IF;
    
    -- 재고 수량 확인
    SELECT stock_qty 
    INTO v_current_qty
    FROM tbl_stock
    WHERE product_code = p_product_code
    FOR UPDATE;
    
    IF v_current_qty < p_discard_qty THEN
        RAISE_APPLICATION_ERROR(-20012, '재고 부족! 현재 재고(' || v_current_qty || '개)보다 많이 폐기할 수 없습니다.');
    END IF;
    
    v_detail_code := 'DI' || LPAD(seq_discard_detail.NEXTVAL,3,'0');

    INSERT INTO tbl_discard_detail (discard_detail_code, discard_id, product_code, discard_qty)
    VALUES (v_detail_code, p_discard_id, p_product_code, p_discard_qty);

    DBMS_OUTPUT.PUT_LINE('폐기상품 추가: ' || p_product_code || ' / 수량: ' || p_discard_qty);
END;

-- 폐기 트리거
-- 폐기 상세에 insert 가 되는 순간 트리거가 발동
-- 재고 테이블에 재고수량 update
-- 재고상세 테이블에 기록 insert

CREATE OR REPLACE TRIGGER ut_discard_outbound AFTER
INSERT ON tbl_discard_detail
FOR EACH ROW
DECLARE
    v_stock_seq NUMBER;
    v_staff_id  VARCHAR2(30);
BEGIN
    UPDATE tbl_stock
    SET stock_qty = stock_qty - :NEW.discard_qty
    WHERE product_code = :NEW.product_code;
    
    SELECT stock_seq INTO v_stock_seq
    FROM tbl_stock
    WHERE product_code = :NEW.product_code;
    
    SELECT staff_id INTO v_staff_id
    FROM tbl_discard
    WHERE discard_id = :NEW.discard_id;

    INSERT INTO tbl_stock_detail (
        stock_detail_code, 
        stock_date, 
        stock_type, 
        qty, 
        bigo, 
        expiry_date, 
        staff_id, 
        stock_seq, 
        product_code
    ) VALUES (
        'SD' || seq_stock_detail_code.NEXTVAL,
        SYSDATE,
        '폐기출고',
        :NEW.discard_qty,
        '폐기번호 ' || :NEW.discard_id || ' 처리완료',
        NULL,
        v_staff_id,
        v_stock_seq, 
        :NEW.product_code
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20101, '폐기 이력 기록 중 필수 데이터(재고/직원)를 찾을 수 없습니다.');
END;

-- 정빈 끝

select * from tbl_order_detail;
select * from tbl_order;
update tbl_order
set order_status = '완료'
where order_id = 'OR65';

select * from tbl_stock;
desc tbl_stock_detail;



SELECT *
FROM tbl_stock_detail;
-- 미성 시작
-- 5. 현재재고 확인(select,) 상품 상세 정보
CREATE OR REPLACE VIEW v_detail_stock AS
SELECT p.scategory_code as 소분류코드, p.product_code as 상품코드, p.product_name as 상품명, stock_qty as 재고, price as 가격
FROM tbl_product p JOIN tbl_stock s ON p.product_code = s.product_code;

select * from v_detail_stock;

-- 5. 현재재고 확인(select,) 상품 상세 정보
CREATE OR REPLACE VIEW v_detail_stock AS
SELECT scategory_code as 상품코드, product_name as 상품명, stock_qty as 재고, price as 가격
FROM tbl_product p JOIN tbl_stock s ON p.product_code = s.product_code;

SELECT *
FROM v_detail_stock
where 상품명 = '신라면';


-- 6. 구매내역 조회(일별 하나만 보여주기)
-- 일일 매출 현황
CREATE OR REPLACE FUNCTION uf_daily_sales
(
    pdate DATE
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(price-discount_amt),0)
    INTO v_total
    FROM tbl_sale s JOIN tbl_sale_detail d ON s.sale_id = d.sale_id
    WHERE TRUNC(s.sale_date) = TRUNC(pdate);
    
    RETURN v_total;
END;

SELECT uf_daily_sales(DATE '2026-06-30')
FROM dual;

-- 일일 상품별 나간 수량 조회
CREATE OR REPLACE VIEW v_daily_sale_stock AS
SELECT
    TRUNC(s.sale_date) AS 판매일자,
    p.product_name AS 상품명,
    SUM(d.qty) AS 판매수량
FROM tbl_sale s JOIN tbl_sale_detail d ON s.sale_id = d.sale_id
                JOIN tbl_product p ON d.product_code = p.product_code
GROUP BY TRUNC(s.sale_date), p.product_name;

SELECT * 
FROM v_daily_sale_stock 
where TRUNC(판매일자) = DATE '2026-06-30';
-- 미성 끝