//+------------------------------------------------------------------+
//|                                               MACD_Histogram.mq4 |
//|                      Copyright © 2008, MetaQuotes Software Corp. |
//|                         http://www.frankie-prasetio.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.frankie-prasetio.blogspot.com"

#define arrowsDisplacement 0.0001
//---- input parameters
extern string separator1 = "*** MACD Settings ***";
extern int FastMAPeriod = 12;
extern int SlowMAPeriod = 26;
extern int SignalMAPeriod = 9;
extern string separator2 = "*** Indicator Settings ***";
extern bool   displayAlert = true;
//---- buffers
double MACDLineBuffer[100];
double SignalLineBuffer[100];
double bullishDivergence[];
double bearishDivergence[];
//---- variables
double alpha = 0;
double alpha_1 = 0;
string buyClassic = "Buy Classical: ";
string sellClassic = "Sell Classical: ";
string buyReverse = "Buy Reverse: ";
string sellReverse = "Sell Reverse: ";
//----
static datetime lastAlertTime;
static string   indicatorName;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
	for (int i = 0; i < 100; i++)
	{
		MACDLineBuffer[i] = 0;
		SignalLineBuffer[i] = 0;
	}
   //----
	  alpha = 2.0 / (SignalMAPeriod + 1.0);
	  alpha_1 = 1.0 - alpha;
   //----
}
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit()
  {

  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   static int IndCounted = -1;
   int limit;
   string macdline, signal;
   int counted_bars = IndCounted - 5;
   IndCounted = Bars;
   //---- check for possible errors
   if(counted_bars < 0) 
       return;
   //---- last counted bar will be recounted
   if(counted_bars > 0) 
       counted_bars--;
   limit = Bars - counted_bars;
   
   CalculateIndicator(counted_bars);

//----
   for(int i = limit; i >= 0; i--)
     {
       MACDLineBuffer[i] = iMA(NULL, 0, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, i) - 
                           iMA(NULL, 0, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
       SignalLineBuffer[i] = alpha*MACDLineBuffer[i] + alpha_1*SignalLineBuffer[i+1];
       
       macdline = macdline + DoubleToStr(MACDLineBuffer[i], Digits) + ", ";
       signal = signal + DoubleToStr(SignalLineBuffer[i], Digits) + ", ";
     }
//----

	Comment(" \nMACD Loaded Successfully™ ", 
	  "\n", sellClassic,
	  "\n", sellReverse,
	  "\n", buyClassic,
	  "\n", buyReverse,
     "\n", "MACD:   ", macdline,
     "\n", "Signal: ", signal
	  "\n", "counted_bars: ", counted_bars, " limit: ", limit, " IndCounted: ", IndCounted
   );
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateIndicator(int countedBars)
  {
   for(int i = Bars - countedBars; i >= 0; i--)
     {
       CalculateMACD(i);
       CatchBullishDivergence(i + 2);
       CatchBearishDivergence(i + 2);
     }              
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateMACD(int i)
  {
   MACDLineBuffer[i] = iMA(NULL, 0, FastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, i) - 
                       iMA(NULL, 0, SlowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, i);
   SignalLineBuffer[i] = alpha*MACDLineBuffer[i] + alpha_1*SignalLineBuffer[i+1];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CatchBullishDivergence(int shift)
  {
   if(IsIndicatorTrough(shift) == false)
       return;  
   int currentTrough = shift;
   int lastTrough = GetIndicatorLastTrough(shift);
//----   
   if(MACDLineBuffer[currentTrough] > MACDLineBuffer[lastTrough] && 
      Low[currentTrough] < Low[lastTrough])
     {
      // bullishDivergence[currentTrough] = MACDLineBuffer[currentTrough] - 
        //                                  arrowsDisplacement;
       if(displayAlert == true)
          DisplayAlert("Classical bullish divergence on: ", 
                        currentTrough);  
	   buyClassic = buyClassic + currentTrough + ", ";
     }
//----   
   if(MACDLineBuffer[currentTrough] < MACDLineBuffer[lastTrough] && 
      Low[currentTrough] > Low[lastTrough])
     {
       //bullishDivergence[currentTrough] = MACDLineBuffer[currentTrough] - 
         //                                 arrowsDisplacement;
        if(displayAlert == true)
           DisplayAlert("Reverse bullish divergence on: ", 
                        currentTrough);  
		buyReverse = buyReverse + currentTrough + ", ";
     }      
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CatchBearishDivergence(int shift)
  {
   if(IsIndicatorPeak(shift) == false)
       return;
   int currentPeak = shift;
   int lastPeak = GetIndicatorLastPeak(shift);
//----   
   if(MACDLineBuffer[currentPeak] < MACDLineBuffer[lastPeak] && 
      High[currentPeak] > High[lastPeak])
     {
      // bearishDivergence[currentPeak] = MACDLineBuffer[currentPeak] + 
       //                                 arrowsDisplacement;
       if(displayAlert == true)
           DisplayAlert("Classical bearish divergence on: ", 
                        currentPeak);  
						
		sellClassic = sellClassic + currentPeak + ", ";				
     }
   if(MACDLineBuffer[currentPeak] > MACDLineBuffer[lastPeak] && 
      High[currentPeak] < High[lastPeak])
     {
      // bearishDivergence[currentPeak] = MACDLineBuffer[currentPeak] + 
         //                               arrowsDisplacement;
        if(displayAlert == true)
           DisplayAlert("Reverse bearish divergence on: ", 
                        currentPeak);   
						
		sellReverse = sellReverse + currentPeak + ", ";
     }   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsIndicatorPeak(int shift)
  {
   if(MACDLineBuffer[shift] >= MACDLineBuffer[shift+1] && MACDLineBuffer[shift] > MACDLineBuffer[shift+2] && 
      MACDLineBuffer[shift] > MACDLineBuffer[shift-1])
       return(true);
   else 
       return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsIndicatorTrough(int shift)
  {
   if(MACDLineBuffer[shift] <= MACDLineBuffer[shift+1] && MACDLineBuffer[shift] < MACDLineBuffer[shift+2] && 
      MACDLineBuffer[shift] < MACDLineBuffer[shift-1])
       return(true);
   else 
       return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetIndicatorLastPeak(int shift)
  {
   for(int i = shift + 5; i < Bars; i++)
     {
       if(SignalLineBuffer[i] >= SignalLineBuffer[i+1] && SignalLineBuffer[i] >= SignalLineBuffer[i+2] &&
          SignalLineBuffer[i] >= SignalLineBuffer[i-1] && SignalLineBuffer[i] >= SignalLineBuffer[i-2])
         {
           for(int j = i; j < Bars; j++)
             {
               if(MACDLineBuffer[j] >= MACDLineBuffer[j+1] && MACDLineBuffer[j] > MACDLineBuffer[j+2] &&
                  MACDLineBuffer[j] >= MACDLineBuffer[j-1] && MACDLineBuffer[j] > MACDLineBuffer[j-2])
                   return(j);
             }
         }
     }
   return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetIndicatorLastTrough(int shift)
  {
    for(int i = shift + 5; i < Bars; i++)
      {
        if(SignalLineBuffer[i] <= SignalLineBuffer[i+1] && SignalLineBuffer[i] <= SignalLineBuffer[i+2] &&
           SignalLineBuffer[i] <= SignalLineBuffer[i-1] && SignalLineBuffer[i] <= SignalLineBuffer[i-2])
          {
            for (int j = i; j < Bars; j++)
              {
                if(MACDLineBuffer[j] <= MACDLineBuffer[j+1] && MACDLineBuffer[j] < MACDLineBuffer[j+2] &&
                   MACDLineBuffer[j] <= MACDLineBuffer[j-1] && MACDLineBuffer[j] < MACDLineBuffer[j-2])
                    return(j);
              }
          }
      }
    return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayAlert(string message, int shift)
  {
   if(shift <= 2 && Time[shift] != lastAlertTime)
     {
       lastAlertTime = Time[shift];
       Alert(message, Symbol(), " , ", Period(), " minutes chart");
     }
  }
//+------------------------------------------------------------------+
