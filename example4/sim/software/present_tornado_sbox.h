/* auxiliary functions */
void sbox__B1 (/*inputs*/ DATATYPE X3__[MASKING_ORDER],DATATYPE X2__[MASKING_ORDER],DATATYPE X1__[MASKING_ORDER],DATATYPE X0__[MASKING_ORDER], /*outputs*/ DATATYPE Y3__[MASKING_ORDER],DATATYPE Y2__[MASKING_ORDER],DATATYPE Y1__[MASKING_ORDER],DATATYPE Y0__[MASKING_ORDER]) {

  // Variables declaration
  DATATYPE T1__[MASKING_ORDER];
  DATATYPE T2__[MASKING_ORDER];
  DATATYPE T3__[MASKING_ORDER];
  DATATYPE T4__[MASKING_ORDER];
  DATATYPE T5__[MASKING_ORDER];
  DATATYPE T6__[MASKING_ORDER];
  DATATYPE T7__[MASKING_ORDER];
  DATATYPE T8__[MASKING_ORDER];
  DATATYPE T9__[MASKING_ORDER];
  DATATYPE _tmp1_[MASKING_ORDER];

  write_to_gpio_bit (0,1);

  // Instructions (body)
  for (int _mask_idx = 0; _mask_idx <= (MASKING_ORDER - 1); _mask_idx++) {
    T1__[_mask_idx] = XOR(X1__[_mask_idx],X2__[_mask_idx]);
  }
  MASKED_AND(T2__,X2__,T1__);
  for (int _mask_idx = 0; _mask_idx <= (MASKING_ORDER - 1); _mask_idx++) {
    T3__[_mask_idx] = XOR(X3__[_mask_idx],T2__[_mask_idx]);
    Y0__[_mask_idx] = XOR(X0__[_mask_idx],T3__[_mask_idx]);
    T5__[_mask_idx] = XOR(T1__[_mask_idx],Y0__[_mask_idx]);
  }
  MASKED_AND(T4__,T1__,T3__);
  for (int _mask_idx = 0; _mask_idx <= (MASKING_ORDER - 1); _mask_idx++) {
    T6__[_mask_idx] = XOR(T4__[_mask_idx],X2__[_mask_idx]);
  }
  MASKED_OR(T7__,X0__,T6__);
  for (int _mask_idx = 0; _mask_idx <= (MASKING_ORDER - 1); _mask_idx++) {
    Y1__[_mask_idx] = XOR(T5__[_mask_idx],T7__[_mask_idx]);
  }
  _tmp1_[0] = NOT(X0__[0]);
  for (int _mask_idx = 1; _mask_idx <= (MASKING_ORDER - 1); _mask_idx++) {
    _tmp1_[_mask_idx] = X0__[_mask_idx];
  }
  for (int _mask_idx = 0; _mask_idx <= (MASKING_ORDER - 1); _mask_idx++) {
    T8__[_mask_idx] = XOR(T6__[_mask_idx],_tmp1_[_mask_idx]);
    Y3__[_mask_idx] = XOR(Y1__[_mask_idx],T8__[_mask_idx]);
  }
  MASKED_OR(T9__,T8__,T5__);
  for (int _mask_idx = 0; _mask_idx <= (MASKING_ORDER - 1); _mask_idx++) {
    Y2__[_mask_idx] = XOR(T3__[_mask_idx],T9__[_mask_idx]);
  }

  write_to_gpio_bit (0,0);
}


