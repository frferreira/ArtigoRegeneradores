/*********************************************
 * OPL 20.1.0.0 Model
 * Author: lcres
 * Creation Date: 5 de mai de 2023 at 10:34:33
 *********************************************/

int M = ...;  // total number of time periods
int P_i = ...;  // number of time periods stoves can operate on gas 
int n = ...;

// Sets
range I = 1..n;  // set of stoves
range T = 1..M;  // set of time periods

// Parameters
float T_min = ...;  // minimum temperature
float T_max = ...;  // maximum temperature
float Q_fuel = ...;  // fuel flow rate
float Q_air = ...;  // air flow rate
float c_fuel = ...;  // cost of fuel per unit
float c_gas = ...;  // cost of natural gas per unit
float Q_gas = ...;  //gas disponível por período

float q[I][T] = ...;  // fuel flow rate for each stove and time period
float a[I][T] = ...;  // air flow rate for each stove and time period

// Variables
dvar boolean x[I][T];  // binary variable indicating whether stove i operates on gas at time t
dvar float+ g[I][T];  // natural gas consumption for each stove and time period
dvar float+ f[T];  // total fuel consumption at each time period
dvar float+ T_stove[I][T];  // temperature of each stove at each time period

// Objective function
minimize
 sum(i in I, t in T) g[i][t] * c_gas;  // minimize natural gas cost
 //+ sum(t in T) f[t] * c_fuel;  // minimize fuel cost

// Constraints
subject to {

  // Each stove can operate on gas for a maximum of P_i time periods
  forall(i in I)
    sum(t in T) x[i][t] <= P_i;
 

  // Total fuel consumption at each time period is equal to Q_fuel times the number of stoves operating on fuel
  forall(t in T)
    f[t] == Q_fuel * sum(i in I) (1 - x[i][t]);

  // Natural gas consumption for each stove and time period is equal to the product of the binary variable x and the natural gas flow rate plus a small positive constant epsilon to avoid division by zero
  forall(i in I, t in T)
    g[i][t] == (x[i][t] * (sum(j in I) q[j][t] - a[i][t]) + 0.01) / 1000;

  // Temperature of each stove at each time period must be within the limits of T_min and T_max
 forall(i in I, t in T)
    T_stove[i][t] >= T_min - 1000 * ( x[i][t]);//(1 - x[i][t])
 //forall(i in I, t in T)
  //  T_stove[i][t] <= T_max + 1000 * (x[i][t]);//(1 - x[i][t])

  // The temperature of each stove at each time period is determined by the fuel and air flow rates
  forall(i in I, t in T)
    T_stove[i][t] == 200 * (sum(j in I) q[j][t] - a[i][t]) + 20 * sum(j in I) a[j][t];

  // The temperature of each stove at each time period must be greater than or equal to T_min
  forall(i in I, t in T)
    T_stove[i][t] >= T_min;

  // The temperature of each stove at each time period must be less than or equal to T_max
  forall(t in T)
  	sum(i in I) g[i][t] <= Q_gas;
}  
 