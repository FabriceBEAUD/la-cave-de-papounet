// API Scan — analyse l'étiquette d'une bouteille de whisky (Mistral vision)
export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const apiKey = process.env.MISTRAL_API_KEY;
  if (!apiKey) return res.status(503).json({ error: 'MISTRAL_API_KEY non configurée.' });

  const { image } = req.body || {};
  if (!image || !image.startsWith('data:image/')) {
    return res.status(400).json({ error: 'Image manquante (data URL attendue).' });
  }

  const prompt = `Tu es un expert en whisky. Analyse la photo de cette bouteille et identifie-la.
Réponds UNIQUEMENT avec un objet JSON (aucun texte autour) au format exact :
{
  "name": "nom complet du whisky avec l'âge si visible (ex: Lagavulin 16 ans)",
  "distillery": "nom de la distillerie",
  "region": "une valeur parmi: Highlands, Lowlands, Speyside, Islay, Campbeltown, Islands, Japon, USA, Irlande, France, Taïwan, Écosse, Autre",
  "type": "une valeur parmi: Single Malt, Blended, Single Grain, Bourbon, Rye, Japonais, Irlandais, Autre",
  "age": nombre d'années d'âge (0 si non précisé / NAS),
  "abv": degré d'alcool en % (nombre, ex 43 ou 46.3 — 40 si illisible),
  "peat": niveau de tourbe de 0 à 5 (0 = aucune, 5 = très tourbé) selon ta connaissance de ce whisky,
  "notes": "courte description des notes de dégustation typiques de ce whisky en français (1-2 phrases)",
  "aromes": ["liste", "de", "tags"] parmi: fruité, floral, miel, caramel, vanille, épicé, chocolat, café, tourbé, fumé, maritime, iodé, agrumes, boisé, sucré, sec,
  "confidence": "haute" ou "moyenne" ou "basse" selon ta certitude d'identification
}
Si tu ne peux pas identifier la bouteille du tout, renvoie {"error": "non identifiable"}.`;

  try {
    const response = await fetch('https://api.mistral.ai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'mistral-small-latest',
        messages: [{
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            { type: 'image_url', image_url: image },
          ],
        }],
        max_tokens: 500,
        temperature: 0.2,
        response_format: { type: 'json_object' },
      }),
    });

    if (!response.ok) {
      const err = await response.text();
      return res.status(502).json({ error: 'Erreur Mistral', detail: err });
    }

    const data = await response.json();
    const raw = data.choices?.[0]?.message?.content ?? '{}';
    let bottle;
    try { bottle = JSON.parse(raw); }
    catch { return res.status(502).json({ error: 'Réponse illisible.' }); }

    return res.status(200).json(bottle);
  } catch (e) {
    return res.status(500).json({ error: 'Erreur interne', detail: e.message });
  }
}
