within SolarTherm.Models.CSP.CRS.Receivers;
model ReceiverTransient
  extends Interfaces.Models.ReceiverFluid;
  Medium.BaseProperties medium;
  SI.SpecificEnthalpy h_in;
  SI.SpecificEnthalpy h_out(start=h_0);
  parameter String file_perf_rec = Modelica.Utilities.Files.loadResource("modelica://SolarTherm/new_feature_functions/acciona_tables/motab_acciona/rec_perf.motab");
  parameter String perf_table = "rec_perf";

  parameter SI.Length H_rcv=1 "Receiver height" annotation(Dialog(group="Technical data"));
  parameter SI.Diameter D_rcv=1 "Receiver diameter" annotation(Dialog(group="Technical data"));
  parameter Integer N_pa = 1 "Number of panels" annotation(Dialog(group="Technical data"));
  parameter SI.Diameter D_tb=1 "Tube outer diameter" annotation(Dialog(group="Technical data"));
  parameter SI.Thickness t_tb=1 "Tube wall thickness" annotation(Dialog(group="Technical data"));
  parameter SI.Efficiency ab=1 "Coating absortance" annotation(Dialog(group="Technical data"));
  parameter SI.Efficiency em=1 "Coating Emitance" annotation(Dialog(group="Technical data"));
  parameter Real N_tb_pa=div(w_pa,D_tb) "Number of tubes";
  
  SI.Temperature T_in=Medium.temperature(state_in) "Temperature at inlet";
  SI.Temperature T_out=Medium.temperature(state_out) "Temperature at outlet";
  Medium.ThermodynamicState state_in=Medium.setState_phX(fluid_a.p,h_in);
  Medium.ThermodynamicState state_out=Medium.setState_phX(fluid_b.p,max(h_0,h_out));

  Modelica.Blocks.Interfaces.RealOutput T(final quantity="ThermodynamicTemperature",
                                          final unit = "K", displayUnit = "degC", min=0) annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={94,0}), iconTransformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={30,0})));

  SI.HeatFlowRate Q_loss;
  SI.HeatFlowRate Q_rcv;
  SI.Efficiency eta_rec;

  Modelica.Blocks.Interfaces.RealInput Tamb annotation (Placement(
        transformation(
        extent={{-12,-12},{12,12}},
        rotation=-90,
        origin={0,84}), iconTransformation(
        extent={{-6,-6},{6,6}},
        rotation=-90,
        origin={0,78})));

  Modelica.Blocks.Interfaces.RealInput Wspd annotation (Placement(
        transformation(
        extent={{-12,-12},{12,12}},
        rotation=-90,
        origin={-20,84}), iconTransformation(
        extent={{-6,-6},{6,6}},
        rotation=-90,
        origin={-20,78})));

  Modelica.Blocks.Sources.RealExpression q_in(y=heat.Q_flow/1e6);

  Modelica.Blocks.Tables.CombiTable2D rec_perf_tab(
    tableOnFile=true,
    tableName=perf_table,
    smoothness=Modelica.Blocks.Types.Smoothness.ContinuousDerivative,
    fileName=file_perf_rec);

protected
  parameter SI.Length w_pa=D_rcv*sin(pi/N_pa) "Panel width"; //w_pa=D_rcv*pi/N_pa
  parameter SI.Volume V_rcv=N_pa*N_tb_pa*H_rcv*pi*(D_tb/2-t_tb)^2;
  parameter SI.Area A=N_pa*N_tb_pa*H_rcv*pi*D_tb/2 "Area";
  parameter Medium.ThermodynamicState state_0=Medium.setState_pTX(1e5,T_0);
  parameter SI.SpecificEnthalpy h_0=Medium.specificEnthalpy(state_0);
  parameter SI.Temperature T_0=from_degC(290) "Start value of temperature"; 
initial equation
  medium.h = h_0;
equation
  connect(Wspd, rec_perf_tab.u2);
  connect(q_in.y, rec_perf_tab.u1);

  medium.h=(h_in+h_out)/2;
  h_in=inStream(fluid_a.h_outflow);
  fluid_b.h_outflow=max(h_0,h_out);
  fluid_a.h_outflow=h_in;
  T = T_out;

  heat.T=medium.T;
  fluid_b.m_flow=-fluid_a.m_flow;
  fluid_a.p=medium.p;
  fluid_b.p=medium.p;

  Q_loss=-ab*heat.Q_flow*(1-eta_rec);//-A*sigma*em*(medium.T^4-Tamb^4);
  medium.d*V_rcv*der(medium.h)+V_rcv*der(medium.d)*medium.h=ab*heat.Q_flow+Q_loss+fluid_a.m_flow*(h_in-h_out);
  Q_rcv=fluid_a.m_flow*(h_out-h_in);
  eta_rec = max(0,rec_perf_tab.y);//Q_rcv/max(1e-3,ab*heat.Q_flow);
annotation(
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.002));
end ReceiverTransient;