/*********************************************
 * OPL 20.1.0.0 Model
 * Author: lcres
 * Creation Date: 18 de mai de 2023 at 19:02:36
 *********************************************/

int Nt = ...;  // numero de fases do regenerador
int Nr = ...;  // numero de regeneradores 

range I = 1..Nr;  // conjunto de regeneradores
range T = 0..Nt;  // conjunto de fases. Será considerado 4 fases
//Case-Based Real-Time Controller and its Application in Combustion Control of Hot Blast Stoves

int V_MIN_bfg = ...;   	//vazao minimo de bfg
int V_MAX_bfg = ...;	//vazao maximo de bfg	
int V_MIN_ng = ...;		//vazao minimo de gas natural
int V_MAX_ng = ...;		//vazao maximo de gas natural
int V_MIN_air = ...;	//vazao minimo de ar
int V_MAX_air = ...;	//vazao maximo de ar
int Disp_bfg = ...;   //disponibilidade de BFG para todos os regeneradores durante todo o ciclo
int TP[I][T] = ...;  //Dados de entrada: Temperatura do regenerador i para o tempo t
//para t = 0, TP é a temperatura inicial do regenerador
//para t = 1, 2, 3 e 4, TP é a temperatura prevista para o final da fases do tempo t 
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
//então o objetivo é minimizar o período de on-gas em um ciclo.

// Uma função objetivo interessante é a minização da quantidade de BFG usado.
// porém, para isso é necessário mudar a restrição 1 para predição por tabela. 
// pois a quantidade é um produto de variáveis e o Cplex não minimiza funções quadraticas. 

subject to{
  
forall (i in I, t in 1..4)
  TP[i][t] == a1*TP[i][t-1] + a2*q_bfg[i][t] + a3*q_ng[i][t] + a4*q_air[i][t] + a5;    
  // A temperatura atual esperada é uma regreção linear da temperatura anterios e quantidades de bfg, ng e ar. 
  //OBS: pode ser feito por tabela para usar outros métodos de predição.
  // Eu irei modelar para colocar no artigo, mas não implementaremos (por enquanto)
 

//quantidade de gas é a vazão multiplicado pelo tempo 
forall (i in I, t in 1..4)
	q_bfg[i][t] == v_bfg[i][t] * t_bfg[i][t];
 	
forall (i in I, t in 1..4)
	q_ng[i][t] == v_ng[i][t] * t_ng[i][t];
	
forall (i in I, t in 1..4)
	q_air[i][t] == v_air[i][t] * t_air[i][t];
	
// a vazão de BFG deve estar entre um Max e Min ou ser zero
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
	//DUVIDA: Eh necessário? Basta garantir ser sempre teremos um 
	//regenerador na fase de on-brast.  


};
 

 