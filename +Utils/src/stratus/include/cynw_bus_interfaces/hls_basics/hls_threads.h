

#pragma once

#define SC_THREAD_CLOCK_RESET(proc, clk, ClockEdge, rst, ResetLevel, ResetSync)  \
			if ( ClockEdge && ResetLevel) {                                       \
				SC_CTHREAD(proc, this->clk.pos());                               	\
				reset_signal_is(this->rst, true);                               \
			} else if ( ClockEdge && !ResetLevel) {                               \
				SC_CTHREAD(proc, this->clk.pos());                                    	\
				reset_signal_is(this->rst, false);                              \
			} else if ( !ClockEdge && ResetLevel) {                               \
				SC_CTHREAD(proc, this->clk.neg());                                    	\
				reset_signal_is(this->rst, true);                               \
			} else if ( !ClockEdge && !ResetLevel) {                              \
				SC_CTHREAD(proc, this->clk.neg());                                    	\
				reset_signal_is(this->rst, false);                              \
			}                                                                   \
//#define SC_THREAD_CLOCK_RESET(proc, clk, ClockEdge, rst, ResetLevel, ResetSync)  \
//        if (  ResetSync ) {                                                     \
//			if ( ClockEdge && ResetLevel) {                                       \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.pos();					\
//				reset_signal_is(this->rst, true);                               \
//			} else if ( ClockEdge && !ResetLevel) {                               \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.pos();					\
//				reset_signal_is(this->rst, false);                              \
//			} else if ( !ClockEdge && ResetLevel) {                               \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.neg();					\
//				reset_signal_is(this->rst, true);                               \
//			} else if ( !ClockEdge && !ResetLevel) {                              \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.neg();					\
//				reset_signal_is(this->rst, false);                              \
//			}                                                                   \
//        } else  {                                                               \
//			if ( ClockEdge && ResetLevel) {                                       \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.pos();					\
//				async_reset_signal_is(this->rst, true);                                \
//			} else if ( ClockEdge && !ResetLevel) {                               \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.pos();					\
//				async_reset_signal_is(this->rst, false);                               \
//			} else if ( !ClockEdge && ResetLevel) {                               \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.neg();					\
//				async_reset_signal_is(this->rst, true);                                \
//			} else if ( !ClockEdge && !ResetLevel) {                              \
//				SC_THREAD(proc);                                    	\
//				this->sensitive << this->clk.neg();					\
//				async_reset_signal_is(this->rst, false);                               \
//			}                                                                   \
//        }


#define SC_THREAD_CLOCK_RESET_TRAITS(proc, clk, reset, traits)  SC_THREAD_CLOCK_RESET(proc, clk, traits::PosEdgeClk, reset, traits::ResetLevel, traits::ResetSync)
