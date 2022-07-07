/* C code by yosys */
/* top =  1  */
/* src = "present_encrypt_sbox.v:23.1-49.10" */
void PRESENT_ENCRYPT_SBOX(MDTYPE* odat, MDTYPE* idat) {

  MDTYPE n00_;
  MDTYPE n01_;
  MDTYPE n02_;
  MDTYPE n03_;
  MDTYPE n04_;
  MDTYPE n05_;
  MDTYPE n06_;
  MDTYPE n07_;
  MDTYPE n08_;
  MDTYPE n09_;
  MDTYPE n10_;
  MDTYPE n11_;
  MDTYPE n12_;
  MDTYPE n13_;
  MDTYPE n14_;
  MDTYPE n15_;
  MDTYPE n16_;
  MDTYPE n17_;
  MDTYPE n18_;
  MDTYPE n19_;
  MDTYPE n20_;
  MDTYPE n21_;
  MDTYPE n22_;
  MDTYPE n23_;
  MDTYPE n24_;
  MDTYPE n25_;
  MDTYPE n26_;
  MDTYPE n27_;
  /* src = "present_encrypt_sbox.v:25.21-25.25" */
  /* src = "present_encrypt_sbox.v:24.21-24.25" */
#if D_==1 
  write_to_gpio_bit (0,1);
  NOT1(idat[1], n27_);
  NOT1(idat[0], n00_);
  NOT1(idat[3], n01_);
  NOT1(idat[2], n02_);
  OR2(idat[1], n02_, n03_);
  XOR2(n00_, idat[3], n04_);
  XOR2(n03_, n04_, odat[0]);
  AND2(idat[0], idat[2], n05_);
  NOT1(n05_, n06_);
  AND2(idat[1], n06_, n07_);
  OR2(idat[3], n07_, n08_);
  AND2(idat[1], idat[0], n09_);
  OR2(idat[2], n09_, n10_);
  NOT1(n10_, n11_);
  OR2(n01_, n05_, n12_);
  OR2(n11_, n12_, n13_);
  AND2(n08_, n13_, odat[1]);
  AND2(idat[0], n02_, n14_);
  OR2(n00_, idat[2], n15_);
  AND2(idat[3], n15_, n16_);
  OR2(n01_, n14_, n17_);
  OR2(n27_, n17_, n18_);
  OR2(n09_, n16_, n19_);
  AND2(n18_, n19_, n20_);
  XOR2(n02_, n20_, odat[2]);
  AND2(idat[1], n02_, n21_);
  OR2(n27_, idat[2], n22_);
  OR2(n17_, n21_, n23_);
  AND2(n00_, n22_, n24_);
  OR2(idat[3], n09_, n25_);
  OR2(n24_, n25_, n26_);
  AND2(n23_, n26_, odat[3]);
  write_to_gpio_bit (0,0);
#else
  int i;
  int rand[46];
  for (i=0 ; i<46 ; i++) {
    rand[i] = get_rand();
  }
  write_to_gpio_bit (0,1);
  NOT1(idat[1], n27_);
  NOT1(idat[0], n00_);
  NOT1(idat[3], n01_);
  NOT1(idat[2], n02_);
  OR2(idat[1], n02_, n03_,rand[0],rand[1]);
  XOR2(n00_, idat[3], n04_);
  XOR2(n03_, n04_, odat[0]);
  AND2(idat[0], idat[2], n05_,rand[2],rand[3]);
  NOT1(n05_, n06_);
  AND2(idat[1], n06_, n07_,rand[4],rand[5]);
  OR2(idat[3], n07_, n08_,rand[6],rand[7]);
  AND2(idat[1], idat[0], n09_,rand[8],rand[9]);
  OR2(idat[2], n09_, n10_,rand[10],rand[11]);
  NOT1(n10_, n11_);
  OR2(n01_, n05_, n12_,rand[12],rand[13]);
  OR2(n11_, n12_, n13_,rand[14],rand[15]);
  AND2(n08_, n13_, odat[1],rand[16],rand[17]);
  AND2(idat[0], n02_, n14_,rand[18],rand[19]);
  OR2(n00_, idat[2], n15_,rand[20],rand[21]);
  AND2(idat[3], n15_, n16_,rand[22],rand[23]);
  OR2(n01_, n14_, n17_,rand[24],rand[25]);
  OR2(n27_, n17_, n18_,rand[26],rand[27]);
  OR2(n09_, n16_, n19_,rand[28],rand[29]);
  AND2(n18_, n19_, n20_,rand[30],rand[31]);
  XOR2(n02_, n20_, odat[2]);
  AND2(idat[1], n02_, n21_,rand[32],rand[33]);
  OR2(n27_, idat[2], n22_,rand[34],rand[35]);
  OR2(n17_, n21_, n23_,rand[36],rand[37]);
  AND2(n00_, n22_, n24_,rand[38],rand[39]);
  OR2(idat[3], n09_, n25_,rand[40],rand[41]);
  OR2(n24_, n25_, n26_,rand[42],rand[43]);
  AND2(n23_, n26_, odat[3],rand[44],rand[45]);
  write_to_gpio_bit (0,0);
#endif
  return;

}
