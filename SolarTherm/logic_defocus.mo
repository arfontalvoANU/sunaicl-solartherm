within SolarTherm;

model logic_defocus
 Modelica.Blocks.Interfaces.RealInput Recpower annotation(
    Placement(visible = true, transformation(extent = {{-126, 74}, {-86, 114}}, rotation = 0), iconTransformation(origin = {-96, 12}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  
    
    parameter Real Rec_max = 700;
    //parameter Real Rec_init = 0;
//     parameter Real level_max = 90;
//    parameter Real level_min = 10;

  Modelica.Blocks.Interfaces.BooleanOutput y
    annotation (Placement(transformation(extent={{98,-10},{118,10}})));
    
algorithm
  when Recpower < 0.90*Rec_max then
    y:=true;
  elsewhen Recpower > 1.05*Rec_max then
    y:=false;
  end when;
initial equation
  y= (Recpower < 0.90*Rec_max) /*(Recpower>level_max) and (Recpower>level_min)*/;
  
/*equation
  when Recpower<Rec_max-5 then
    y=true;
  elsewhen Recpower>Rec_max+5 then
    y=false;
  end when;
*/  
  
//  when (Recpower > Rec_max) then
//    y=true;
//  elsewhen (Recpower < Rec_init) then
//    y=false;
//  end when;

  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));


end logic_defocus;