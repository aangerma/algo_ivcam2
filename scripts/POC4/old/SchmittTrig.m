%SCHMITT TRIGGER
%SchmittTrig(x,tL,tH,PF)
function [y] = SchmittTrig(x,tL,tH,PF)


 limit=0;
if nargin<3
   disp('number of inputs arguments should be three');
end
   N=length(x);
  
   y=[length(x)];
  

   
   for i=1:N
       
       
      if ( limit ==0)
          
          y(i)=0;
          
      elseif (limit == 1)
           
           y(i)=1;
           
      end
       
       
      if (x(i)<=tL)
          limit=0; 
            y(i)=0;
          
      elseif( x(i)>= tH)         
          limit=1;  
          y(i)=1;
              
      end
      
         
   end
  
   if PF
  plot(x,'r','DisplayName','plot of x','LineWidth',1.5); hold on;
  plot(y,'blue','DisplayName','plot of y','LineWidth',3); hold off;
  legend('show');
  title('Schmitt Trigger')
   end