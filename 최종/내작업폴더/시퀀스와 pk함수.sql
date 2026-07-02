-- 결제번호 시퀀스
CREATE SEQUENCE SEQ_PAYMENT
START WITH 71
INCREMENT BY 1
NOCACHE
NOCYCLE;

-- 결제상세번호 시퀀스
CREATE SEQUENCE SEQ_PAYMENT_DETAIL
START WITH 101
INCREMENT BY 1
NOCACHE
NOCYCLE;

-- 판매상세번호 시퀀스
CREATE SEQUENCE SEQ_SALE_DETAIL
START WITH 201
INCREMENT BY 1
NOCACHE
NOCYCLE;

-- 재고상세번호 시퀀스
CREATE SEQUENCE SEQ_STOCK_DETAIL
START WITH 201
INCREMENT BY 1
NOCACHE
NOCYCLE;
-- 
/*
    함수명 : UF_NEXT_PAYMENT

    작성자 : 조지훈

    기능
    - 결제번호(PAY_DETAIL_ID)를 생성한다.
    - Oracle Sequence와 접두어(PA)를 조합하여 문자열 PK를 반환한다.

    예)
    PA071
    PA072
    PA073
*/
CREATE OR REPLACE FUNCTION UF_NEXT_PAYMENT
RETURN TBL_PAYMENT.PAY_DETAIL_ID%TYPE
IS
    -- 반환할 결제번호
    V_PAYMENT_ID TBL_PAYMENT.PAY_DETAIL_ID%TYPE;
BEGIN

    -- 시퀀스 번호 앞에 PA를 붙여 결제번호 생성
    V_PAYMENT_ID :=
        'PA' || LPAD(SEQ_PAYMENT.NEXTVAL, 3, '0');

    RETURN V_PAYMENT_ID;

END;
/
/*
==========================================================
 Function Name : UF_NEXT_PAYMENT_DETAIL
 Description   : 결제상세번호 생성 함수
 Author        : 조지훈
 Date          : 2026-07-01
==========================================================

기능
- 결제상세번호(PAY_DETAIL_NUMBER)를 생성한다.
- Oracle Sequence와 접두어(PAD)를 조합하여 문자열 PK를 반환한다.

예)
PAD101
PAD102
PAD103
==========================================================
*/

CREATE OR REPLACE FUNCTION UF_NEXT_PAYMENT_DETAIL
RETURN TBL_PAYMENT_DETAIL.PAY_DETAIL_NUMBER%TYPE
IS
    -- 반환할 결제상세번호
    V_PAYMENT_DETAIL_ID TBL_PAYMENT_DETAIL.PAY_DETAIL_NUMBER%TYPE;
BEGIN

    -- 시퀀스 번호 앞에 PAD를 붙여 결제상세번호 생성
    V_PAYMENT_DETAIL_ID :=
        'PAD' || LPAD(SEQ_PAYMENT_DETAIL.NEXTVAL, 3, '0');

    RETURN V_PAYMENT_DETAIL_ID;

END;
/
show errors;
/*
==========================================================
 Function Name : UF_NEXT_SALE_DETAIL
 Description   : 판매상세번호 생성 함수
 Author        : 조지훈
 Date          : 2026-07-01
==========================================================

기능
- 판매상세번호(SALE_DETAIL_ID)를 생성한다.
- Oracle Sequence와 접두어(SAD)를 조합하여 문자열 PK를 반환한다.

예)
SAD201
SAD202
SAD203
==========================================================
*/

CREATE OR REPLACE FUNCTION UF_NEXT_SALE_DETAIL
RETURN TBL_SALE_DETAIL.SALE_DETAIL_ID%TYPE
IS
    -- 반환할 판매상세번호
    V_SALE_DETAIL_ID TBL_SALE_DETAIL.SALE_DETAIL_ID%TYPE;
BEGIN

    -- 시퀀스 번호 앞에 SAD를 붙여 판매상세번호 생성
    V_SALE_DETAIL_ID :=
        'SAD' || LPAD(SEQ_SALE_DETAIL.NEXTVAL, 3, '0');

    RETURN V_SALE_DETAIL_ID;

END;
/
/*
==========================================================
 Function Name : UF_NEXT_STOCK_DETAIL
 Description   : 재고상세번호 생성 함수
 Author        : 조지훈
 Date          : 2026-07-01
==========================================================

기능
- 재고상세번호(STOCK_DETAIL_ID)를 생성한다.
- Oracle Sequence와 접두어(SD)를 조합하여 문자열 PK를 반환한다.

예)
SD201
SD202
SD203
==========================================================
*/

CREATE OR REPLACE FUNCTION UF_NEXT_STOCK_DETAIL
RETURN TBL_STOCK_DETAIL.STOCK_DETAIL_CODE%TYPE
IS
    -- 반환할 재고상세번호
    V_STOCK_DETAIL_ID TBL_STOCK_DETAIL.STOCK_DETAIL_CODE%TYPE;
BEGIN

    -- 시퀀스 번호 앞에 SD를 붙여 재고상세번호 생성
    V_STOCK_DETAIL_ID :=
        'SD' || LPAD(SEQ_STOCK_DETAIL.NEXTVAL, 3, '0');

    RETURN V_STOCK_DETAIL_ID;

END;
/