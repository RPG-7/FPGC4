int main() {
	unsigned int buf[10];
	char cbuf[10];
	long lbuf[10];

	buf[0] = 50;
	buf[1] = 51;
	buf[2] = 52;
	buf[3] = 53;
	buf[4] = 54;

	unsigned int b = buf[0]+buf[1];


	cbuf[0] = 30;
	cbuf[1] = 31;
	cbuf[2] = 32;
	cbuf[3] = 33;
	cbuf[4] = 34;

	char c = cbuf[0]+cbuf[1];


	lbuf[0] = 30;
	lbuf[1] = 31;
	lbuf[2] = 32;
	lbuf[3] = 33;
	lbuf[4] = 34;

	long d = lbuf[0]+lbuf[1];

	return (int)d; //61
}

void int1()
{

}

void int2()
{
	
}

void int3()
{
	
}

void int4()
{
	
}