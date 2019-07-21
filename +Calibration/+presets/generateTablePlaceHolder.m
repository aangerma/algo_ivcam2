name = [{'bias_factor'          }
    {'bias_offset'          }
    {'modulation_ref_factor'}
    {'modulation_ref_offset'}
    {'pulse_width_ctrl'     }
    {'snubber_cap_control'  }
    {'snubber_res_control'  }
    {'Gain_Trim'            }
    {'SigPath_LFC'          }
    {'Amb_Dis'              }
    {'cmpratesel'           }
    {'cmppeak'              }
    {'coarse_masking_min'   }
    {'coarse_masking_max'   }
    {'bpfEn'                }
    {'bpfCutoff'            }
    {'bpfGain'              }
    {'lpfEn'                }
    {'lpfGain'              }
    {'lpfCutOff'            }
    {'ampdet_RateSel'       }
    {'DESTconfactIn'        }
    {'DESTconfactOt'        }
    {'DESTconfq'            }
    {'DESTconfw1'           }
    {'DESTconfw2'           }
    {'DESTconfIRbitshift'   }
    {'DESTconfv'            }
    {'JFILinvConfThr'       }
    {'JFILinvMinMax'        }
    {'VBROffset'            }
    {'AlgoThermalLoopScale' }
    {'AlgoThermalLoopOffset'}
    {'JFILgammaScale'}
    {'JFILgammaShift'}
    {'DCORcoarseMasking_002'}];
%%
type =[{'single'}
    {'single'}
    {'single'  }
    {'single'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint16'  }
    {'uint16'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint8'  }
    {'uint32'   }
    {'uint32'   }
    {'uint16'  }
    {'uint32'   }
    {'uint32'   }
    {'uint8'  }
    {'uint32'   }
    {'uint8'  }
    {'uint32'   }
    {'single' }
    {'single'   }
    {'single'   }
    {'uint32'   }
    {'uint32'   }
    {'uint32'   }];
    %%
    value = uint32(zeros(size(name)));
    
    dynamicRangePlaceHolder = table(name,type,value);