within SolarTherm;

model TestPBTransient_fix
   extends Interfaces.Models.PowerBlock;
   Medium.BaseProperties medium;
  replaceable package Medium = SolarTherm.Media.MoltenSalt.MoltenSalt_ph;

  parameter SI.HeatFlowRate W_des=111e6 "Design turbine gross output" annotation (Dialog(group="Design"));
  parameter SI.Temperature T_in_ref=from_degC(565) "HTF inlet temperature (design)" annotation (Dialog(group="Design"));
  parameter SI.Temperature T_out_ref=from_degC(146) "HTF outlet temperature (design)"
                                                                                     annotation (Dialog(group="Design"));
  parameter SI.AbsolutePressure p_bo=10e5 "Boiler operating pressure" annotation (Dialog(group="Design"));
  //parameter SI.HeatFlowRate Q_flow_ref=294.118e6 "Design thermal power" annotation (Dialog(group="Design"));
  parameter SI.HeatFlowRate Q_flow_ref=294.118e6 "Design thermal power" annotation (Dialog(group="Design"));

  parameter Real nu_min=0.25 "Minimum turbine operation" annotation (Dialog(group="Operating strategy"));
  SI.HeatFlowRate Q_flow( final start=0) "Cycle heat addition";
  SI.Temperature T_in=Medium.temperature(state_in);
  SI.Temperature T_out=Medium.temperature(state_out);
  Real eff_pb "Power Block Efficiency";

  parameter Boolean enable_losses = false
    "= true enable thermal losses with environment"
      annotation (Dialog(group="Assumptions"), Evaluate=true, HideResult=true, choices(checkBox=true));
  parameter SI.Temperature T_des=from_degC(43) "Ambient temperature at design" annotation (Dialog(group="Assumptions",enable = enable_losses));

  parameter Boolean external_parasities = false
    "= true enable parasities as an input"
      annotation (Dialog(group="Parasities energy losses"), Evaluate=true, HideResult=true, choices(checkBox=true));
  parameter Real nu_net=0.9 "Estimated gross to net conversion factor at the power block" annotation(Dialog(group="Parasities energy losses"));
  parameter Real W_base=0.0055*294.188e6 "Power consumed at all times" annotation(Dialog(group="Parasities energy losses"));

  Modelica.Fluid.Interfaces.FluidPort_a fluid_a2(redeclare package Medium = Medium) annotation (Placement(
        visible = true,transformation(extent = {{-54, -4}, {-34, 16}}, rotation = 0),  iconTransformation(extent = {{-54, -6}, {-46, 2}}, rotation = 0)));

  Modelica.Blocks.Interfaces.RealInput T_amb if enable_losses annotation (Placement(
        visible = true,transformation(
        origin={-12,80},extent={{-12,-12},{12,12}},
        rotation=-90),                  iconTransformation(
        
        origin={-20,60},extent={{-6,-6},{6,6}},
        rotation=-90)));
  replaceable model Cycle =
     SolarTherm.Models.PowerBlocks.Correlation.Rankine constrainedby
    SolarTherm.Models.PowerBlocks.Correlation.Cycle
    annotation (Dialog(group="Regresion"),choicesAllMatching=true);
  Cycle cycle(T_in=T_in,load=load,final T_in_ref=T_in_ref);
  replaceable model Cooling = SolarTherm.Models.PowerBlocks.Cooling.NoCooling constrainedby
    SolarTherm.Models.PowerBlocks.Cooling.Cooling
    annotation (Dialog(group="Cooling losses",enable = enable_losses),
      choicesAllMatching=true);
  Cooling cool(T_amb=T_amb_internal);
  Real load;
  SI.HeatFlowRate W_gross "Parasitic losses power";
  SI.HeatFlowRate W_loss "Parasitic losses power";
  //SI.HeatFlowRate W_net "Estimated net output at design";
  SI.Energy E_gross(final start=0, fixed=true, displayUnit="MW.h");
  SI.Energy E_net(final start=0, fixed=true, displayUnit="MW.h");

  Boolean logic;

   Modelica.Blocks.Interfaces.RealInput parasities if external_parasities annotation (Placement(
        visible = true,transformation(
        origin={18,80},extent={{-12,-12},{12,12}},
        rotation=-90),                  iconTransformation(
        
        origin={20,60},extent={{-6,-6},{6,6}},
        rotation=-90)));

  Modelica.Blocks.Interfaces.RealOutput T(final quantity="ThermodynamicTemperature",
                                          final unit = "K", displayUnit = "degC", min=0) annotation (Placement(visible = true,transformation(
        
        origin={-58, -16},extent={{10, -10}, {-10, 10}},
        rotation=0), iconTransformation(
        
        origin={-55, -23},extent={{-5, -5}, {5, 5}},
        rotation= 180)));

  Modelica.Blocks.Interfaces.RealInput parasities_internal;
  Real k_q;
  Real k_w;
  SI.SpecificEnthalpy h_in;
  SI.SpecificEnthalpy h_in_a2;
  //SI.SpecificEnthalpy h_out;
  //SI.SpecificEnthalpy h_out(start=h_0);
  SI.SpecificEnthalpy h_mea(start = h_out_ref);
  
  parameter SI.MassFlowRate m_flow_ref= Q_flow_ref/(h_in_ref-h_out_ref);

  Medium.ThermodynamicState state_in=Medium.setState_phX(fluid_a.p,inStream(fluid_a.h_outflow));
  Medium.ThermodynamicState state_out=Medium.setState_phX(fluid_a.p,h_mea);
  parameter Medium.ThermodynamicState state_in_ref=Medium.setState_pTX(1e5,T_in_ref);
  parameter Medium.ThermodynamicState state_out_ref=Medium.setState_pTX(1e5,T_out_ref);
  parameter SI.SpecificEnthalpy h_in_ref=Medium.specificEnthalpy(state_in_ref);
  parameter SI.SpecificEnthalpy h_out_ref=Medium.specificEnthalpy(state_out_ref);

  //parameter SI.MassFlowRate m_flow_min= nu_minm_flow_ref*nu_min;

  Modelica.Blocks.Interfaces.RealInput T_amb_internal;

  parameter Real nu_eps=0.1;
  //SI.HeatFlowRate Q_rcv;
  parameter SI.Volume V_rcv=2000;
  
  initial equation
  medium.h = h_out_ref;

equation
  if enable_losses then
    connect(T_amb_internal,T_amb);
  else
    T_amb_internal=T_des;
  end if;
  if external_parasities then
    connect(parasities_internal,parasities);
  else
    parasities_internal=0;
  end if;

  logic=load>nu_min;
 medium.h=(h_in+h_mea)/2;
  h_in=inStream(fluid_a.h_outflow);
  h_in_a2=inStream(fluid_a2.h_outflow);
  fluid_b.h_outflow=max(h_out_ref,h_mea);
  //h_out=fluid_b.h_outflow;
//  h_out=fluid_a.h_outflow;
//  h_out=fluid_a2.h_outflow;
  h_in=fluid_a.h_outflow;
  h_in_a2=fluid_a2.h_outflow;
  fluid_a2.m_flow + fluid_a.m_flow + fluid_b.m_flow=0;
//  fluid_a.p=fluid_b.p;
//  fluid_a.p=fluid_a2.p;
  fluid_a2.p=medium.p;
  fluid_a.p=medium.p;
  fluid_b.p=medium.p;
  
  
  //fluid_a.m_flow*h_in + fluid_a2.m_flow*h_in_a2 - max(1e-3,-fluid_b.m_flow)*h_mea = 0;
  
  
   T = SolarTherm.Media.MoltenSalt.MoltenSalt_utilities.T_h(h_mea);
  //T = SolarTherm.Media.MoltenSalt.MoltenSalt_utilities.T_h(h_mea);from_degC(T_h(h_mea))
  
  //
  //T = T_out;
  
  //medium.h=(h_in+h_out)/2;
  //h_in=inStream(fluid_a.h_outflow);
  //fluid_b.h_outflow=max(h_0,h_out);
  //fluid_a.h_outflow=h_in;
  //T = T_out;

  //heat.T=medium.T;
//  fluid_b.m_flow=-fluid_a.m_flow;
//  fluid_a.p=medium.p;
//  fluid_b.p=medium.p;
//fluid_a.m_flow*h_in + fluid_a2.m_flow*h_in_a2 - max(1e-3,-fluid_b.m_flow)*h_mea = 0;

  //eta_rec = max(0,rec_perf_tab.y);
  //Q_rcv = fluid_a.m_flow*(h_mea-h_in);
  //Q_loss = if heat.Q_flow > 1e-3 then ab*heat.Q_flow*(1-eta_rec) else A*sigma*em*(medium.T^4-Tamb^4);
  //Q_inc = heat.Q_flow/1e6;
  //Q_perd = Q_loss/1e6;
  //medium.d*V_rcv*der(medium.u) + medium.u*V_rcv*der(medium.d) = ab*heat.Q_flow - Q_loss + fluid_a.m_flow*(h_in-h_mea);
  //medium.d*V_rcv*der(medium.u) + medium.u*V_rcv*der(medium.d) =  -fluid_a.m_flow*h_in - fluid_a2.m_flow*h_in_a2 + max(1e-3,-fluid_b.m_flow)*h_mea;
  
  
  //medium.d*V_rcv*der(medium.u) + medium.u*V_rcv*der(medium.d)= fluid_a.m_flow*h_in + fluid_a2.m_flow*h_in_a2 - max(1e-3,-fluid_b.m_flow)*h_mea + Q_flow;
  
  medium.d*V_rcv*der(medium.u) + medium.u*V_rcv*der(medium.d)= fluid_a.m_flow*h_in + fluid_a2.m_flow*h_in_a2 - max(1e-3,-fluid_b.m_flow)*h_mea - Q_flow;
  ///le cambie el signo a fluid_b.m_flow
  

//  load=max(nu_eps,(fluid_a.m_flow+fluid_a2.m_flow)/m_flow_ref); //load=1 if it is no able partial load
 // load=max(1e-3,(fluid_a.m_flow+fluid_a2.m_flow)/m_flow_ref); //load=1 if it is no able partial load
  load=max(1e-3,(fluid_a2.m_flow)/m_flow_ref); //load=1 if it is no able partial load

  if logic then
    k_q=cycle.k_q;
    k_w=cycle.k_w;
   // fluid_a.m_flow*h_in + fluid_a2.m_flow*h_in_a2 - max(1e-3,-fluid_b.m_flow)*h_mea - Q_flow = 0;
  else
    k_q=0;
    k_w=0;
//    h_out=h_out_ref;
  end if;

  Q_flow/(cool.nu_q*Q_flow_ref*load)=k_q;
  W_gross/(cool.nu_w*W_des*load)=k_w;
  eff_pb=W_gross/max(1,Q_flow);

  der(E_gross)=W_gross;
  der(E_net)=W_net;
  W_loss=(1-nu_net)*W_gross+W_base+parasities_internal;
  W_net = W_gross - W_loss;

end TestPBTransient_fix;