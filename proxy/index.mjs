const SOURCES = [
  'https://api.airplanes.live/v2/point/64.5/15/700',
  'https://api.adsb.lol/v2/lat/64.5/lng/15/dist/950',
];

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET',
  'Content-Type': 'application/json',
  'Cache-Control': 'max-age=20',
};

export const handler = async () => {
  for (const url of SOURCES) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(8000) });
      if (!res.ok) continue;
      const data = await res.json();
      if (data.ac?.length > 0) {
        return { statusCode: 200, headers: CORS, body: JSON.stringify(data) };
      }
    } catch { continue; }
  }
  return { statusCode: 503, headers: CORS, body: '{"error":"no data"}' };
};