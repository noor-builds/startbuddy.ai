import PDFDocument from 'pdfkit';
import { createChatModel } from './llm.js';
import { supabaseAdmin } from '../../db.js';
import { randomUUID } from 'crypto';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';

const STARTUP_DOCS_BUCKET = process.env.SUPABASE_STARTUP_DOCS_BUCKET ?? 'startup docs';

const DOC_TYPES = {
  pitch_deck: 'Pitch Deck Outline',
  business_plan: 'Business Plan',
  problem_solution: 'Problem-Solution Document',
  model_canvas: 'Business Model Canvas',
  validation_report: 'Validation Report',
  user_persona: 'User Persona Sheet',
  gtm_strategy: 'Go-To-Market Strategy'
};

function buildPdfBuffer(title, contentText) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 50, size: 'A4' });
    const chunks = [];

    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    // Title
    doc.fontSize(22).fillColor('#0D2247').text(title, { align: 'center', underline: true });
    doc.moveDown(2);

    // Parse content text line by line for simple styling
    const lines = contentText.split('\n');
    doc.fillColor('#333333').fontSize(11);

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) {
        doc.moveDown(0.5);
        continue;
      }

      if (trimmed.startsWith('# ')) {
        doc.moveDown();
        doc.fontSize(18).fillColor('#0D2247').text(trimmed.replace('# ', ''), { bold: true });
        doc.fontSize(11).fillColor('#333333');
      } else if (trimmed.startsWith('## ')) {
        doc.moveDown(0.7);
        doc.fontSize(14).fillColor('#0B1E36').text(trimmed.replace('## ', ''), { bold: true });
        doc.fontSize(11).fillColor('#333333');
      } else if (trimmed.startsWith('### ')) {
        doc.moveDown(0.5);
        doc.fontSize(12).fillColor('#0B1E36').text(trimmed.replace('### ', ''), { bold: true });
        doc.fontSize(11).fillColor('#333333');
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        doc.text(`• ${trimmed.substring(2)}`, { indent: 15 });
      } else {
        doc.text(trimmed, { align: 'justify' });
      }
      doc.moveDown(0.2);
    }

    doc.end();
  });
}

async function uploadPdfToStorage({ authId, title, pdfBuffer }) {
  const safeName = String(title).trim().toLowerCase().replace(/[^a-zA-Z0-9._-]+/g, '-').slice(0, 80);
  const fileName = `${safeName}-${randomUUID()}.pdf`;
  const storagePath = `documents/${authId}/${fileName}`;

  const { error: uploadError } = await supabaseAdmin.storage
    .from(STARTUP_DOCS_BUCKET)
    .upload(storagePath, pdfBuffer, {
      contentType: 'application/pdf',
      cacheControl: '3600',
      upsert: false,
    });

  if (uploadError) {
    throw new Error(`Failed to upload document PDF: ${uploadError.message}`);
  }

  const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin.storage
    .from(STARTUP_DOCS_BUCKET)
    .createSignedUrl(storagePath, 60 * 60 * 24 * 365); // 1 year signed URL

  if (signedUrlError) {
    throw new Error(`Failed to sign document URL: ${signedUrlError.message}`);
  }

  return signedUrlData.signedUrl;
}

async function generateDocument({ authId, startupId, type }) {
  const title = DOC_TYPES[type];
  if (!title) {
    throw new Error(`Invalid document type: ${type}. Supported types: ${Object.keys(DOC_TYPES).join(', ')}`);
  }

  // 1. Fetch startup details
  const { data: startup, error: startupError } = await supabaseAdmin
    .from('startup')
    .select('id, startupName, description')
    .eq('id', startupId)
    .eq('authid', authId)
    .single();

  if (startupError || !startup) {
    throw new Error('Startup not found: ' + (startupError?.message ?? ''));
  }

  // 2. Query Gemini
  const model = createChatModel({ temperature: 0.4 });
  const response = await model.invoke([
    new SystemMessage(
      `You are an expert startup co-founder and copywriter.
Generate a comprehensive, professionally written "${title}" document.
Ensure the content is detailed, highly specific to the startup, and action-oriented.
Format the output in clean, valid Markdown using # for main headings and ## for sub-sections.
Do not use generic placeholders.`
    ),
    new HumanMessage(
      `Startup Name: ${startup.startupName}\nStartup Description: ${startup.description}`
    ),
  ]);

  const contentText = typeof response.text === 'string'
    ? response.text.trim()
    : String(response.content ?? '').trim();

  // 3. Build PDF Buffer
  const pdfBuffer = await buildPdfBuffer(title, contentText);

  // 4. Upload to storage
  const fileUrl = await uploadPdfToStorage({ authId, title, pdfBuffer });

  // 5. Save to documents table
  const { data: doc, error: docError } = await supabaseAdmin
    .from('documents')
    .insert({
      authid: authId,
      startup_id: startupId,
      title: title,
      type: type,
      content: contentText,
      file_url: fileUrl
    })
    .select()
    .single();

  if (docError) {
    throw new Error('Failed to save document record: ' + docError.message);
  }

  return doc;
}

export { generateDocument };
