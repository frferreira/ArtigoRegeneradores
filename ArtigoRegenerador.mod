/*********************************************
 * OPL 20.1.0.0 Model
 * Author: lcres
 * Creation Date: 18 de mai de 2023 at 19:02:36
 *********************************************/

int Nt = ...;  // numero de fases do regenerador
int Nr = ...;  // numero de regeneradores 

range I = 1..Nr;  // conjunto de regeneradores
range T = 0..Nt;  // conjunto de fases. Ser� considerado 4 fases
//Case-Based Real-Time Controller and its Application in Combustion Control of Hot Blast Stoves

int V_MIN_bfg = ...;   	//vazao minimo de bfg
int V_MAX_bfg = ...;	//vazao maximo de bfg	
int V_MIN_ng = ...;		//vazao minimo de gas natural
int V_MAX_ng = ...;		//vazao maximo de gas natural
int V_MIN_air = ...;	//vazao minimo de ar
int V_MAX_air = ...;	//vazao maximo de ar
int Disp_bfg = ...;   //disponibilidade de BFG para todos os regeneradores durante todo o ciclo
int TP[I][T] = ...;  //Dados de entrada: Temperatura do regenerador i para o tempo t
//para t = 0, TP � a temperatura inicial do regenerador
//para t = 1, 2, 3 e 4, TP � a temperatura prevista para o final da fases do tempo t 


// inseridos pelo fabricio 

int a = ...;  //temperatura do domo
int b = ...;  //fluxo de g�s de combust�o BFG 
int c = ...; // tempo de on-gas.
float targetTempDomo = ...;

// vari�vel Tempo representa o conjunto de �ndices que representa os diferentes pontos ou momentos no tempo durante o processo de aquecimento do domo.
range Tempo = 1..Nt;  // Substitua T pelo n�mero m�ximo de momentos no tempo desejado

//A vari�vel taxa_aumento_domo representa a taxa de aumento desejada para a temperatura do domo durante a fase de on-gas. � um valor num�rico que determina o ritmo de aumento da temperatura do domo
float taxa_aumento_domo = 10.0;  // Substitua 10.0 pelo valor desejado da taxa de aumento


range Indices = 1..N;  // Substitua N pelo n�mero m�ximo de �ndices relevante para o problema

//observei semelhan�a com a vari�vel TP
dvar float+  temperatura_domo[I][T];  // Temperatura do domo de um regenerador em cada momento no tempo
dvar float+  temperatura_ar[I][T];  
dvar int clico_regenerador[I][T];  // clico de um 
dvar boolean on_gas[Tempo];           // Indicador de fase de on-gas em cada momento no tempo
dvar boolean on_blast[Tempo];



// at� aqui 


float a1 = ...;
float a2 = ...;
float a3 = ...;
float a4 = ...;
float a5 = ...;

dvar float+  v_bfg[I][t in 1..Nt];
dvar float+  v_ng[I][t in 1..Nt];
dvar float+  v_air[I][t in 1..Nt];
dvar float+  t_bfg[I][t in 1..Nt];
dvar float+  t_ng[I][t in 1..Nt];
dvar float+  t_air[I][t in 1..Nt];
dvar float+  q_bfg[I][t in 1..Nt];
dvar float+  q_ng[I][t in 1..Nt];
dvar float+  q_air[I][t in 1..Nt];


minimize
	t_bfg[1][3] + t_bfg[2][4] + t_bfg[3][0] + t_bfg[4][2];   
//para o regenerador 1 a fase de on-gas termina na fases 3, para o regenerador
// 2 a fase de on-gas termina da fases 4, assim sucessivamente. 
//ent�o o objetivo � minimizar o per�odo de on-gas em um ciclo.

// Uma fun��o objetivo interessante � a miniza��o da quantidade de BFG usado.
// por�m, para isso � necess�rio mudar a restri��o 1 para predi��o por tabela. 
// pois a quantidade � um produto de vari�veis e o Cplex n�o minimiza fun��es quadraticas. 

subject to{
  
forall (i in I, t in 1..4)
  TP[i][t] == a1*TP[i][t-1] + a2*q_bfg[i][t] + a3*q_ng[i][t] + a4*q_air[i][t] + a5;    
  // A temperatura atual esperada � uma regre��o linear da temperatura anterios e quantidades de bfg, ng e ar. 
  //OBS: pode ser feito por tabela para usar outros m�todos de predi��o.
  // Eu irei modelar para colocar no artigo, mas n�o implementaremos (por enquanto)
 

//quantidade de gas � a vaz�o multiplicado pelo tempo 
forall (i in I, t in 1..4)
	q_bfg[i][t] == v_bfg[i][t] * t_bfg[i][t];
 	
forall (i in I, t in 1..4)
	q_ng[i][t] == v_ng[i][t] * t_ng[i][t];
	
forall (i in I, t in 1..4)
	q_air[i][t] == v_air[i][t] * t_air[i][t];
	
// a vaz�o de BFG deve estar entre um Max e Min ou ser zero
// analogo para gas natural e ar
forall (i in I, t in 1..4) 
	(V_MIN_bfg <= v_bfg[i][t] <= V_MAX_bfg) || (v_bfg[i][t] == 0);

forall (i in I, t in 1..4) 
	(V_MIN_ng <= v_ng[i][t] <= V_MAX_ng) || (v_ng[i][t] == 0);

forall (i in I, t in 1..4) 
	(V_MIN_air <= v_air[i][t] <= V_MAX_air) || (v_air[i][t] == 0);
	
//disponibilidade de BFG
sum(i in I, t in 1..4) q_bfg[i][t] <= Disp_bfg;

forall (i in I, t in 1..4) 
	t_bfg[i][t] == t_ng[i][t] == t_air[i][t];
	//garante o sincronismo entre todas as fases de cada regenerador
	//DUVIDA: Eh necess�rio? Basta garantir ser sempre teremos um 
	//regenerador na fase de on-brast.  


// C�lculo do tempo de on-gas
// Rela��o entre a temperatura de domo e tempo de on-gas  
// Se a temperatura do domo estiver abaixo do valor desejado ou se o fluxo de g�s de combust�o BFG estiver baixo, 
// a restri��o ir� aumentar o tempo de on-gas necess�rio para atingir a temperatura desejada.
forall (i in I, t in T) {
   on_gas[t] >= ((temperatura_domo[i][t] - targetTempDomo) / (a * bfgFlow[t])) + c;
}


// Restri��o 14: rela��o entre a temperatura de domo e o ar de sopro durante o on-blast
forall (i in Indices) {
   temperatura_domo[i] <= temperatura_ar[i] + delta_temperatura_ar_sopro[i];
   temperatura_domo[i] >= temperatura_ar[i] + delta_temperatura_minima_ar_sopro[i];
}



// 1) A temperatura do ar de sopro para o BF acima de 1.000� C
// Restri��o: temperatura do ar de sopro acima de 1000�C
forall (i in Indices, t in Tempo) {
   temperatura_ar[i][t] >= 1000;
}


// 2) Durante a fase de sopro o DOMO deve ter uma temperatura est�vel definida
// Restri��o 12: temperatura est�vel do domo durante o on-blast
forall (i in I, t in Tempo) { 
  on_blast[t] => (temperatura_domo[i][t] >= 1200 && temperatura_domo[i][t] <= 1400);
  
} 

 
// 3) A temperatura do DOMO deve ter uma taxa de aumento e o valor alvo, para ser atingida durante a fase de on-gas

// Restri��o: Taxa de aumento da temperatura do DOMO durante a fase de on-gas
forall (i in I, t in Tempo : t > 1) {
   on_gas[t] => temperatura_domo[i][t] - temperatura_domo[i][t-1] <= taxa_aumento_domo;
}


// 4) A temperatura de DOMO deve atingir a temperatura estavel durante a vase de aquecimento rapido, primeira etapa do on-gas o  mais r�pido poss�vel
// Vari�veis envolvidas
// Restri��o: Atingir a temperatura est�vel durante a fase de aquecimento r�pido (primeira etapa do on-gas) o mais r�pido poss�vel
forall (t in Tempo : t > 1) {
   on_gas[t] => temperatura_domo[t] >= temperatura_estavel;
}


// 5) A vaz�o do ar de sopro deve ser entre um MAX e um MIN ou ser Zero na fase de on-gas
// Vari�veis envolvidas
//dvar float+ vazao_ar_sopro[Tempo];  // Vaz�o do ar de sopro em cada momento no tempo
//dvar boolean on_gas[Tempo];        // Indicador de fase de on-gas em cada momento no tempo

// Restri��o: A vaz�o do ar de sopro deve ser entre um MAX e um MIN ou ser Zero na fase de on-gas
forall (t in Tempo) {
   if (on_gas[t]) {
      vazao_ar_sopro[t] == 0;  // Se estiver na fase de on-gas, a vaz�o do ar de sopro deve ser zero
   } else {
      vazao_ar_sopro[t] >= Vazao_Minima;  // Vaz�o m�nima permitida do ar de sopro
      vazao_ar_sopro[t] <= Vazao_Maxima;  // Vaz�o m�xima permitida do ar de sopro
   }
}


//

};
 

 