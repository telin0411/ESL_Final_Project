#include<stdio.h>
#include<stdlib.h>
#include<fcntl.h>
#include<termios.h>
#include<string.h>
#include<unistd.h>
#include<errno.h>
#include<stdbool.h>
#include<limits.h>
#include<sys/select.h>
#include<math.h>

#define BUFLEN 255
#define ZDEBUG  1
#define V_WRITE_TIMES 1

int openserial(char* sdevfile) {
  int _serial_d = open(sdevfile, O_RDWR | O_NOCTTY);
  if(_serial_d==-1) {
    perror("Unable to open device\n");
  }
  return _serial_d;
}

void clean_buffer () 
{
	fflush (stdin);
	while ( getchar()!='\n');
}

int main(int argc, char** argv)
{
  int serial_d, serial_n;
  speed_t speed, speed_n;
  struct termios soptions, soptions_org;
  struct termios soptions_n, soptions_org_n;
  char command, reg;
  int sent_c, recv_c;
  int sent_n_c, recv_n_c;
  int i,j;
  unsigned char sensor_index=0+'0'; //indexes are ASCII-based
  char wcommand;
  unsigned char send_buf[BUFLEN];
  unsigned char recv_buf[BUFLEN];
  unsigned char send_n_buf[BUFLEN];
  unsigned char recv_n_buf[BUFLEN];
  double theta;
  int cal_x, cal_y, cal_z;
  int acc_x, acc_y, acc_z;
  int data_x, data_y, data_z;
  unsigned timecycle=0;
  int g_value;
  bool wait=true;
  int start=0;
  const int sample = 30; //output file will contain 4*sample points
  FILE *xdata_fp;
  FILE *lock_fp;
  int file_index=0; //file extensions: .1, .2,...
  const char* filebase="xdata.";
  const int num_file=2;
  char filename[BUFLEN];
  char filename2[BUFLEN];
	
  if(argc == 1){ //no port specified
    printf("Usage: zstar3-test sensor_index port: \"zstar3-test 0 /dev/ttyACM0\"\n");
    printf("\"sensor_index\" is used to select sensors if multiple sensors are detected by USB transceiver.\n");
    printf("\"/dev/ttyACM0\" is a USB serial device (cdc_acm kernel module) to support serial control to modems.\n");
    printf("Parameter: /dev/ttyUSB0 [command]\n"); 
    printf("\"/dev/ttyUSB0\" is a USB serial device to support serial control.\n");
    return 1;
  } 

  sensor_index=argv[1][0]; //0123456789:;<=>? or is it 0123456789ABCDEF?

  serial_d = openserial(argv[2]);
  serial_n = openserial(argv[3]);
  if(serial_d == -1) return 1;
  if(serial_n == -1) return 1;

  //Begin of setup serial ports
  tcgetattr(serial_d, &soptions_org);
  tcgetattr(serial_d, &soptions);
  tcgetattr(serial_n, &soptions_org_n);
  tcgetattr(serial_n, &soptions_n);

  speed = B115200; // Speed options: B19200, B38400, B57600, B115200
  speed_n = B9600; // Speed options: B19200, B38400, B57600, B115200
  cfsetispeed(&soptions, speed);
  cfsetospeed(&soptions, speed);
  cfsetispeed(&soptions_n, speed_n);
  cfsetospeed(&soptions_n, speed_n);
	
  // Enable the reciver and set local mode...
  soptions.c_cflag |= ( CLOCAL | CREAD );
  soptions_n.c_cflag |= ( CLOCAL | CREAD );
  // Setting Parity Checking (8N1)
  soptions.c_cflag &= ~PARENB;
  soptions.c_cflag &= ~CSTOPB;
  soptions.c_cflag &= ~CSIZE;
  soptions.c_cflag |= CS8;
  soptions_n.c_cflag &= ~PARENB;
  soptions_n.c_cflag &= ~CSTOPB;
  soptions_n.c_cflag &= ~CSIZE;
  soptions_n.c_cflag |= CS8;

  //Local setting
  //soptions.c_lflag = (ICANON | ECHO | ECHOE); //canonical
  soptions.c_lflag =  ~(ICANON | ECHO | ECHOE | ISIG); //noncanonical
  soptions_n.c_lflag =  ~(ICANON | ECHO | ECHOE | ISIG); //noncanonical

  //Input setting
  //soptions.c_iflag |= (IXON | IXOFF | IXANY); //software flow control
  soptions.c_iflag |= (INPCK | ISTRIP);
  soptions.c_iflag = IGNPAR;
  soptions_n.c_iflag |= (INPCK | ISTRIP);
  soptions_n.c_iflag = IGNPAR;

  //Output setting
  soptions.c_oflag = 0;
  soptions.c_oflag &= ~OPOST;
  soptions_n.c_oflag = 0;
  soptions_n.c_oflag &= ~OPOST;

  //Read options
  soptions.c_cc[VTIME] = 0; 
  soptions.c_cc[VMIN] = 1; //transfer at least 1 character or block
  soptions_n.c_cc[VTIME] = 0; 
  soptions_n.c_cc[VMIN] = 1; //transfer at least 1 character or block

  //Apply setting
  tcsetattr(serial_d, TCSANOW, &soptions);
  tcsetattr(serial_n, TCSANOW, &soptions_n);
  //End of setup serial ports

  //Stop burst mode (in case where previous runs of zstar3-test are interrupted prematurely)
  wcommand = 'x'; //Send 'x' to stop burst mode
  sent_c = write(serial_d, &wcommand, 1);
  tcdrain(serial_d);
  memset(recv_buf, '\0', BUFLEN);
  recv_c = read(serial_d, recv_buf, 255); //Read back 'X" and all other buffers
  tcdrain(serial_d);
  //Clear all previous buffers
  usleep(200000); //Have to wait before flush out I/O buffers
  tcflush(serial_d,TCIOFLUSH);
  tcdrain(serial_d);
  tcsetattr(serial_d, TCSANOW, &soptions);

  //Send 'N' to select the sensor   
  memset(send_buf, '\0', BUFLEN);
  send_buf[0] = 'N'; 
  send_buf[1] = sensor_index;  //retrieved from argv[1]
  printf("Detecting sensor %c.\n", send_buf[1]);
  //debug
  #ifdef ZDEBUG 
  printf("N command send: %c %c\n", send_buf[0], send_buf[1]);
  #endif 
  sent_c = write(serial_d, &send_buf, 2);
  if(sent_c!=2){
	printf("Cannot send N command.\n");
	tcsetattr(serial_d, TCSANOW, &soptions_org);
	close(serial_d);
	exit(1);
  }
  tcdrain(serial_d);
  //Read back response for N command
  memset(recv_buf, '\0', BUFLEN);
  recv_c = read(serial_d, &recv_buf[start], 2);
  tcdrain(serial_d);
  //debug
  #ifdef ZDEBUG 
  printf("N command receive: %c %c\n", recv_buf[0], recv_buf[1]);
  #endif 
  tcdrain(serial_d);
  if(recv_buf[0]!='n'){
	printf("Wrong response from N command.\n");
	tcsetattr(serial_d, TCSANOW, &soptions_org);
	close(serial_d);
	exit(1);
  }
  if(recv_buf[1]!=sensor_index){ 
	printf("Sensor %c is not available.\n", sensor_index+'0');
	exit(1);
  }

  //Send 'R' to 3-axis
  wcommand = 'R'; //Reset sensor to 8bit mode ('r' for 16bit mode)
  printf("Resetting to 8-bit mode\n");
  sent_c = write(serial_d, &wcommand, 1);
  tcdrain(serial_d);
  // Handshake: Wait for 3-axis ready
  memset(recv_buf, '\0', BUFLEN);
  recv_c = read(serial_d, &recv_buf[start], 1);
  tcdrain(serial_d);
  if(recv_buf[0]=='N') printf("Reset done!\n"); //Debug 
  else {
	printf("Response not correct: %c.\n", recv_buf[0]);
	tcsetattr(serial_d, TCSANOW, &soptions_org);
	close(serial_d);
	exit(1);
  }

  //Burst mode
  //8 bit 30Hz Example M0 mode
  //[7427C9000000150100]
  //[ttttttmmxxyyzzddss]
  //01234567890123456789
  //8 bit 120Hz Example M1 mode
  //[414AA08001FF150101FF150101FF150102FF130100]
  //[ttttttmmxxyyzzddxxyyzzddxxyyzzddxxyyzzddss]
  //01234567890123456789012345678901234567890123
  //0         1         2         3         4

  //Send 'g' to change the data rate to 120Hz
  memset(send_buf, '\0', BUFLEN);
  send_buf[0] = 'g'; 
  send_buf[1] ='2';  
  #ifdef ZDEBUG 
  printf("g command send: %c %c\n", send_buf[0], send_buf[1]);
  #endif 
  sent_c = write(serial_d, &send_buf, 2);
  tcdrain(serial_d);
  if(sent_c!=2){
	printf("Cannot send M command.\n");
	tcsetattr(serial_d, TCSANOW, &soptions_org);
	close(serial_d);
	exit(1);
  }
  //Read back response for g command
  memset(recv_buf, '\0', BUFLEN);
  recv_c = read(serial_d, recv_buf, 9);
  tcdrain(serial_d);
  #ifdef ZDEBUG 
  printf("g command receive: %c %c %d %s\n", recv_buf[0], recv_buf[1], recv_buf[2], &recv_buf[3]);
  #endif 
  /*turn off error detection for now*/
  if(recv_buf[0]!='G'){
	printf("Wrong response from g command.\n");
	tcsetattr(serial_d, TCSANOW, &soptions_org);
	close(serial_d);
	exit(1);
  }

  //Send 'M' to change the data rate to 120Hz
  memset(send_buf, '\0', BUFLEN);
  send_buf[0] = 'M';
  send_buf[1] = '1';  
  #ifdef ZDEBUG 
  printf("M command send: %c %c\n", send_buf[0], send_buf[1]);
  #endif 
  sent_c = write(serial_d, &send_buf, 2);
  if(sent_c!=2){
	printf("Cannot send M command.\n");
	tcsetattr(serial_d, TCSANOW, &soptions_org);
	close(serial_d);
	exit(1);
  }
  tcdrain(serial_d);
  //Read back response for M command
  memset(recv_buf, '\0', BUFLEN);
  recv_c = read(serial_d, recv_buf, 9);
  #ifdef ZDEBUG 
  printf("M command receive: %c %c\n", recv_buf[0], recv_buf[1]);
  #endif 
  tcdrain(serial_d);
  /*turn off error detection for now*/
  if(recv_buf[0]!='m'){
	printf("Wrong response from M command.\n");
	tcsetattr(serial_d, TCSANOW, &soptions_org);
	close(serial_d);
	exit(1);
  }

  //Write preambles to file (including timecycle)
  printf("Start Measuring...\n");
  //Remove all xdata files
  for(i=0;i<num_file;i++){ //0..9
	 memset(filename2, '\0', BUFLEN);
	 sprintf(filename2, "%s%d", filebase, i);
	 remove(filename2);  //delete xdata.*  
  }
  file_index=0;
  memset(filename, '\0', BUFLEN);
  sprintf(filename, "%s%d", filebase, file_index);
  xdata_fp = fopen(filename, "w"); //open xdata.0
  /*
  memset(filename2, '\0', BUFLEN);
  sprintf(filename2, "%s%d", filebase, (file_index+1)%num_file);
  lock_fp = fopen(filename2, "w"); //open the next file to prevent xmlhttprequest to run away
  */

  while(1){
     timecycle=timecycle++; //time counter
     fprintf(xdata_fp, "{\"time\":%d,\n", timecycle);
     fprintf(xdata_fp, "\"xarray\":[\n");

     for(i=0; i<sample; i++){

      wcommand = 'V';
      for (j = 0; j < V_WRITE_TIMES; j++) {
      // Request data: Send 'V' to 3-axis
      sent_c = write(serial_d, &wcommand, 1);
      tcdrain(serial_d);
      }//end for
      // Receive data: Wait for 3-axis ready

	  memset(recv_buf, '\0', BUFLEN);
	  recv_c = read(serial_d, &recv_buf[start], 20);
	  tcdrain(serial_d);
        
	  sscanf((char*)&recv_buf[1], "%c", &data_x);
	  sscanf((char*)&recv_buf[3], "%c", &data_y);
	  sscanf((char*)&recv_buf[5], "%c", &data_z);
	  acc_x=(signed char)data_x;
	  acc_y=(signed char)data_y;
	  acc_z=(signed char)data_z;

	  // angle
          double s=22.0; 
	  theta=acos((double)(data_z/s));
	  theta=theta*180/3.1415926;
	  
	  //fprintf(xdata_fp, "[%d, %d, %d],\n", acc_x,  acc_y, acc_z);
	  #ifdef ZDEBUG 
	  printf("X command receive: (%d %d %d). angle= %lf .\n", acc_x, acc_y, acc_z,theta);
	  //XBee
		//printf("Enter command ('q' to exit): " );
		//scanf("%c", &command);
		if(acc_y<-15 && acc_y>-22 && acc_z>0){
			command='b';	
			printf("Sending command %c...\n", command);
			sent_n_c = write(serial_n, &command, 1); //Send command
			usleep(1000000); // Wait for response
			tcdrain(serial_n);	
			memset(recv_n_buf, '\0', BUFLEN);
			recv_n_c = read(serial_n, recv_n_buf, 255); //Get response message
			tcdrain(serial_n);
			printf("%s\n\n",recv_n_buf);		
		}
		if(acc_y>15 && acc_y<35 && acc_z>0){
		        command='f';
			printf("Sending command %c...\n", command);
			sent_n_c = write(serial_n, &command, 1); //Send command
			usleep(1000000); // Wait for response
			tcdrain(serial_n);	
			memset(recv_n_buf, '\0', BUFLEN);
			recv_n_c = read(serial_n, recv_n_buf, 255); //Get response message
			tcdrain(serial_n);
			printf("%s\n\n",recv_n_buf);		
		}
		if(acc_x>12 && acc_x<35 && acc_z>0){
			command='r';
			printf("Sending command %c...\n", command);
			sent_n_c = write(serial_n, &command, 1); //Send command
			usleep(1000000); // Wait for response
			tcdrain(serial_n);	
			memset(recv_n_buf, '\0', BUFLEN);
			recv_n_c = read(serial_n, recv_n_buf, 255); //Get response message
			tcdrain(serial_n);
			printf("%s\n\n",recv_n_buf);		
		}
		if(acc_x<-12 && acc_x>-22 && acc_z>0){
			command='l';
			printf("Sending command %c...\n", command);
			sent_n_c = write(serial_n, &command, 1); //Send command
			usleep(1000000); // Wait for response
			tcdrain(serial_n);
			memset(recv_n_buf, '\0', BUFLEN);
			recv_n_c = read(serial_n, recv_n_buf, 255); //Get response message
			tcdrain(serial_n);
			printf("%s\n\n",recv_n_buf);		
		}
		if(acc_z<-8 && acc_x > 5){
			command='u';
			printf("Sending command %c...\n", command);
			sent_n_c = write(serial_n, &command, 1); //Send command
			usleep(1000000); // Wait for response
			tcdrain(serial_n);	
			memset(recv_n_buf, '\0', BUFLEN);
			recv_n_c = read(serial_n, recv_n_buf, 255); //Get response message
			tcdrain(serial_n);
			printf("%s\n\n",recv_n_buf);		
		}
		if(acc_z<-8 && acc_x < -5){
			command='d';
			printf("Sending command %c...\n", command);
			sent_n_c = write(serial_n, &command, 1); //Send command
			usleep(1000000); // Wait for response			tcdrain(serial_n);	
			memset(recv_n_buf, '\0', BUFLEN);
			recv_n_c = read(serial_n, recv_n_buf, 255); //Get response message
			tcdrain(serial_n);
			printf("%s\n\n",recv_n_buf);		
		}
		if(acc_z<-8 && acc_y > 12){
			command='s';
			printf("Sending command %c...\n", command);
			sent_n_c = write(serial_n, &command, 1); //Send command
			usleep(1000000); // Wait for response			tcdrain(serial_n);	
			memset(recv_n_buf, '\0', BUFLEN);
			recv_n_c = read(serial_n, recv_n_buf, 255); //Get response message
			tcdrain(serial_n);
			printf("%s\n\n",recv_n_buf);		
		}
		//clean_buffer();
		if (command == 'q')
		{
			printf ("Bye!\n");
			break;
		}

	  

	  //usleep(50000);
	  #endif

	  if(i!=(sample-1)){
		  fprintf(xdata_fp, "[%d, %d, %d],\n", acc_x,  acc_y, acc_z);
	  }
	  else{ //Last sample
		  fprintf(xdata_fp, "[%d, %d, %d]\n", acc_x,  acc_y, acc_z);
	  }
	  usleep(100000);
	  
	  //Get cycle counts
	  //sscanf((char*)&recv_buf[1], "%6x", &timecycle);
	  #ifdef ZDEBUG 
	  //printf("Timestamp: %d.\n", timecycle);
	  #endif 
	  //usleep(10000); //wait 10ms before getting next sample
     }
	//Write postscript to file
	fprintf(xdata_fp, "]\n}\n");
	fclose(xdata_fp);

	//Handle next set of files
	file_index=(file_index+1)%num_file; //cycle to next file index
	memset(filename, '\0', BUFLEN);
	sprintf(filename, "%s%d", filebase, file_index);
	xdata_fp = fopen(filename, "w"); //open the next file to prevent xmlhttprequest to run away.
	if(file_index==0){
	   //wait 20ms for xmlhttprequest to catch up before getting next batch of samples
	   //usleep(20000); 

	}
  }
  wcommand = 'x'; //Send 'x' to stop burst mode
  sent_c = write(serial_d, &wcommand, 1);
  tcdrain(serial_d);
  memset(recv_buf, '\0', BUFLEN);
  recv_c = read(serial_d, recv_buf, 1);
  tcdrain(serial_d);

  //restore setting and close
  tcsetattr(serial_d, TCSANOW, &soptions_org);
  close(serial_d);
  return 0;
}

