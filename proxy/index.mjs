const SOURCES = [
  'https://api.airplanes.live/v2/point/64.5/15/700',
  'https://api.adsb.lol/v2/lat/64.5/lng/15/dist/950',
  'https://opensky-network.org/api/states/all?lamin=57&lomin=4&lamax=72&lomax=32',
  'https://opendata.adsb.fi/api/v2/lat/64.5/lon/15/dist/950',
];

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET',
  'Content-Type': 'application/json',
  'Cache-Control': 'max-age=20',
};

export const handler = async () => {
  const errors = [];

  for (const url of SOURCES) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(9000) });
      const text = await res.text();

      if (!res.ok) {
        errors.push(`${url} → HTTP ${res.status}`);
        continue;
      }

      const data = JSON.parse(text);

      // adsb-format (airplanes.live, adsb.lol, adsb.fi)
      if (Array.isArray(data.ac) && data.ac.length > 0) {
        console.log(`OK: ${url} — ${data.ac.length} aircraft`);
        return { statusCode: 200, headers: CORS, body: JSON.stringify(data) };
      }

      // OpenSky format
      if (Array.isArray(data.states) && data.states.length > 0) {
        console.log(`OK: ${url} — ${data.states.length} aircraft`);
        return { statusCode: 200, headers: CORS, body: JSON.stringify(data) };
      }

      errors.push(`${url} → empty data`);
    } catch (e) {
      errors.push(`${url} → ${e.message}`);
    }
  }

  console.error('All sources failed:', errors);
  return {
    statusCode: 503,
    headers: CORS,
    body: JSON.stringify({ error: 'no data', details: errors }),
  };
};