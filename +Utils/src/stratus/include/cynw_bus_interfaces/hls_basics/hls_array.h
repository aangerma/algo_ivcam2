

#pragma once

namespace cynw {

template <typename T, unsigned N, unsigned FILELINE=0>
class hls_array
{
public:
  hls_array()
  {
    sc_assert(N > 0);

    for (unsigned i=0; i < N; i++)
    {
      array[i] = T();
    }
  }

  T& operator[](unsigned i)
  {
    if (i >= N)
    {
      std::stringstream str;
      str << "Out of bound index in hls_array. Array size: " << N << ". Out of bound index: " << i << ". Array declared at line #: " << FILELINE;
      SC_REPORT_WARNING("/hls_array",  str.str().c_str());
      i = 0;
    }

    return array[i];
  }

private:
  T array[N];
};



#ifdef STRATUS
#define HLS_ARRAY(name, T, N)	T name  [ N ]
#else
#define HLS_ARRAY(name, T, N)	hls_array<T, N, __LINE__> name
#endif

}; // namespace cynw
