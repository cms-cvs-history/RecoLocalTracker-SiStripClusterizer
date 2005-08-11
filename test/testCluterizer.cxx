#include "DataFormats/SiStripCluster/interface/SiStripCluster.h"
#include "DataFormats/SiStripDigi/interface/StripDigi.h"

#include <vector>
#include <algorithm>
#include <cmath>
#include <iostream>
#include <exception>

using namespace std;

vector<StripDigi> getDigis() {
  vector<StripDigi> result;
  for (int i=0; i<512; i++) {
    if (i%20 == 0) {
      result.push_back( StripDigi( i, 200));
      result.push_back( StripDigi( i+1, 200));
    }
  }

  for (vector<StripDigi>::const_iterator i=result.begin(); i!=result.end(); i++) {
    cout << i->strip() << " " << i->adc() << endl;
  }

  return result;
}

void dumpClusters(const vector<TkStripCluster>& clusters) {
  for (vector<TkStripCluster>::const_iterator i=clusters.begin(); i!=clusters.end(); i++) {
    cout << "Cluster has size " << i->amplitudes().size() << " " 
	 << " barycenter " << i->barycenter() << " "
	 << " first strip " << i->firstStrip() << " "
	 << " detId " << i->geographicalId() << endl;
  }

}

vector<TkStripCluster> clusterize( vector<StripDigi>::const_iterator begin,
				   vector<StripDigi>::const_iterator end,
				   unsigned int detid,
				   const vector<float>& noiseVec,
				   float seedThreshold, float channelThreshold, float clusterThreshold,
				   const vector<short>& badChannels);


int main() {

  vector<StripDigi> digis = getDigis();
  vector<float> noiseVec(512,2);
  vector<short> badChannels;
  float seedThreshold = 3.0;
  float channelThreshold = 2.0;
  float clusterThreshold = 2.0;

  try {
    cout << "calling clusters..." << endl;
    vector<TkStripCluster> clusters = clusterize(digis.begin(), digis.end(), 22, noiseVec, 
						 seedThreshold, channelThreshold, clusterThreshold,
						 badChannels);
    cout << "calling dumpClusters" << endl;

    dumpClusters( clusters);
  }
  catch (exception& e) {
    cout << "Oops, got an exception!" << endl;
  }
}

bool badChannel( int channel, const vector<short>& badChannels) {
  const int linearCutoff = 10;
  if (badChannels.size() < linearCutoff) {
    return (find( badChannels.begin(), badChannels.end(), channel) != badChannels.end());
  }
  else return binary_search( badChannels.begin(), badChannels.end(), channel);
}

class AboveSeed {
public:
  AboveSeed( float aseed,  const vector<float>& noiseVec) : seed(aseed), noiseVec_(noiseVec) {}

  // FIXME: uses boundary checking with at(), should be replaced with faster operator[]
  // when debugged
  bool operator()(const StripDigi& digi) { return digi.adc() >= seed * noiseVec_.at(digi.channel());}
private:
  float seed;
  const vector<float>& noiseVec_;
};
vector<TkStripCluster> clusterize( vector<StripDigi>::const_iterator begin,
				   vector<StripDigi>::const_iterator end,
				   unsigned int detid,
				   const vector<float>& noiseVec,
				   float seedThreshold, float channelThreshold, float clusterThreshold,
				   const vector<short>& badChannels)
{
  typedef vector<StripDigi> DigiContainer;
  // const int maxBadChannels_ = 1;
  const int max_holes = 0;

  DigiContainer::const_iterator ibeg, iend, ihigh, itest, i;  
  ibeg = iend = begin;
  DigiContainer my_digis; my_digis.reserve(10);

  vector<TkStripCluster> rhits; rhits.reserve( (end - begin)/3 + 1);

  cout << "before while loop..." << endl;

  while ( ibeg != end &&
          (ihigh = find_if( ibeg, end, AboveSeed(seedThreshold,noiseVec))) != end) {

    cout << ihigh->channel() << endl;

    // The seed strip is ihigh. Scan up and down from it, finding nearby strips above
    // threshold, allowing for some holes. The accepted cluster runs from strip ibeg
    // to iend, and itest is the strip under study, not yet accepted.
    iend = ihigh;
    itest = iend + 1;
    while ( itest != end && (itest->strip() - iend->strip() <= max_holes+1)) {
      float channelNoise = noiseVec.at(itest->channel());  
      if ( itest->adc() >= static_cast<int>( channelThreshold * channelNoise)) { 
         iend = itest;
      }
      ++itest;
    }
    ibeg = ihigh;
    itest = ibeg - 1;
    while ( itest >= begin &&
               (ibeg->strip() - itest->strip() <= max_holes+1)) {
      float channelNoise = noiseVec.at(itest->channel());   
      if ( itest->adc() >= static_cast<int>( channelThreshold * channelNoise)) { 
        ibeg = itest;
      }
      --itest;
    }
    /*
   // The seed strip is ihigh. Scan up and down from it, finding nearby strips above
    // threshold, allowing for some holes. The accepted cluster runs from strip ibeg
    // to iend.
    iend = ihigh;
    int badChannelCount = 0;
    for (iend=ihigh+1; iend != end; iend++) {
      if (!badChannel( iend->channel(), badChannels)) {
	badChannelCount = 0;

	cout << "iend channel not bad " << endl;

	if (iend->adc() < static_cast<int>( channelThreshold * noiseVec.at(iend->channel()))) {

	  cout << "iend channel below threshold, stopping search " << endl;

	  break;
	}
      }
      else if (++badChannelCount > maxBadChannels_) break;
    }
    for (ibeg=ihigh-1; ibeg >= begin; ibeg--) {
      if (!badChannel( ibeg->channel(), badChannels)) {
	badChannelCount = 0;
	if (ibeg->adc() < static_cast<int>( channelThreshold * noiseVec.at(ibeg->channel()))) {
	  break;
	}
      }
      else if (++badChannelCount > maxBadChannels_) break;
    }
    */

    int charge = 0;
    float sigmaNoise2=0;
    my_digis.clear();
    for (i=ibeg; i<=iend; i++) {
      float channelNoise = noiseVec.at(i->channel());
      if ( i->adc() >= static_cast<int>( channelThreshold*channelNoise)) {
	// FIXME: should the digi be tested for badChannel before using the adc?
        charge += i->adc();
        sigmaNoise2 += channelNoise*channelNoise;
        my_digis.push_back(*i);
      }
    }
    float sigmaNoise = sqrt(sigmaNoise2);

    if (charge >= static_cast<int>( clusterThreshold*sigmaNoise)) {
      rhits.push_back( TkStripCluster( detid, TkStripCluster::StripDigiRange( my_digis.begin(),
									      my_digis.end())));
    }
    ibeg = iend+1;
  }   
  return rhits;
}

