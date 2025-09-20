function doPost(e) {
  try {
    // Check for secret parameter
    const secret = e.parameter.secret;
    if (secret !== 'budget2761') {
      return ContentService.createTextOutput('Unauthorized').setMimeType(ContentService.MimeType.TEXT);
    }

    // Parse the JSON body
    const data = JSON.parse(e.postData.contents);
    const type = data.type;

    // Get or create the spreadsheet
    const spreadsheet = getOrCreateSpreadsheet();

    if (type === 'transaction') {
      handleTransaction(spreadsheet, data);
    } else if (type === 'category') {
      handleCategory(spreadsheet, data);
    } else if (type === 'paymentMethod') {
      handlePaymentMethod(spreadsheet, data);
    } else {
      throw new Error('Unknown type: ' + type);
    }

    return ContentService.createTextOutput('Success').setMimeType(ContentService.MimeType.TEXT);
  } catch (error) {
    console.error('Error in doPost:', error);
    return ContentService.createTextOutput('Error: ' + error.message).setMimeType(ContentService.MimeType.TEXT);
  }
}

// FIXED: Single doGet with proper JSON responses
function doGet(e) {
  try {
    const secret = e.parameter.secret;
    if (secret !== 'budget2761') {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        message: 'Unauthorized',
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const action = e.parameter.action;
    if (action === 'getTransactions') {
      return getTransactions(e);
    } else if (action === 'getCategories') {
      return getCategories(e);
    } else if (action === 'getPaymentMethods') {
      return getPaymentMethods(e);
    }

    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      message: 'Unknown action: ' + action,
      data: []
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    console.error('Error in doGet:', error);
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      message: 'Error: ' + error.message,
      data: []
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function getOrCreateSpreadsheet() {
  // Use your actual spreadsheet ID
  const SPREADSHEET_ID = '1cabXQLcwfX8_FRCpkgM88JFRYaAc_EGoJzLnMTbZ6a4';
  try {
    const spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
    console.log('Successfully opened existing spreadsheet');
    return spreadsheet;
  } catch (error) {
    console.error('Error opening spreadsheet:', error);
    throw new Error('Could not open spreadsheet with ID: ' + SPREADSHEET_ID + '. Error: ' + error.message);
  }
}

function handleTransaction(spreadsheet, data) {
  const sheet = getOrCreateSheet(spreadsheet, 'Transactions', [
    'remoteID', 'amount', 'categoryName', 'paymentMethod', 'merchantName', 'note', 'dateISO', 'transactionType'
  ]);

  // Parse the amount - handle both numeric and currency text formats
  let parsedAmount = parseAmount(data.amount);

  // Adjust amount based on transactionType
  if (data.transactionType && data.transactionType.toLowerCase() === 'expense') {
    parsedAmount = Math.abs(parsedAmount) * -1;
    console.log('💸 EXPENSE -> negative amount:', parsedAmount);
  } else if (data.transactionType && data.transactionType.toLowerCase() === 'income') {
    parsedAmount = Math.abs(parsedAmount);
    console.log('💰 INCOME -> positive amount:', parsedAmount);
  }

  const rowData = [
    data.remoteID || '',
    parsedAmount,
    data.categoryName || '',
    data.paymentMethod || '',
    data.merchantName || '',
    data.note || '',
    data.dateISO || '',
    data.transactionType || ''
  ];

  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(30000);
    SpreadsheetApp.flush();
    const lastRow = sheet.getLastRow();
    const targetRow = lastRow + 1;
    sheet.getRange(targetRow, 1, 1, rowData.length).setValues([rowData]);
    SpreadsheetApp.flush();
    console.log('✅ Added transaction at row', targetRow, rowData);
  } catch (e) {
    console.error('❌ Write failed:', e);
    throw new Error('Failed to write transaction: ' + e.message);
  } finally {
    lock.releaseLock();
  }
}

function handleCategory(spreadsheet, data) {
  const sheet = getOrCreateSheet(spreadsheet, 'Categories', [
    'remoteID', 'name', 'emoji', 'sortIndex', 'isIncome', 'timestamp'
  ]);

  const rowData = [
    data.remoteID || '',
    data.name || '',
    data.emoji || '',
    data.sortIndex != null ? data.sortIndex : '',
    data.isIncome != null ? data.isIncome : '',
    new Date().toISOString()
  ];

  sheet.appendRow(rowData);
  console.log('✅ Added category');
}

function handlePaymentMethod(spreadsheet, data) {
  const sheet = getOrCreateSheet(spreadsheet, 'PaymentMethods', [
    'remoteID', 'name', 'emoji', 'sortIndex', 'timestamp'
  ]);

  const rowData = [
    data.remoteID || '',
    data.name || '',
    data.emoji || '',
    data.sortIndex != null ? data.sortIndex : '',
    new Date().toISOString()
  ];

  sheet.appendRow(rowData);
  console.log('✅ Added payment method');
}

function getOrCreateSheet(spreadsheet, sheetName, headers) {
  let sheet = spreadsheet.getSheetByName(sheetName);

  if (!sheet) {
    sheet = spreadsheet.insertSheet(sheetName);
    if (headers && headers.length > 0) {
      const headerRange = sheet.getRange(1, 1, 1, headers.length);
      headerRange.setValues([headers]);
      headerRange.setFontWeight('bold').setBackground('#f0f0f0');
    }
    console.log('Created sheet:', sheetName);
  } else {
    // Ensure headers are present and correct
    if (headers && headers.length > 0) {
      const lastCol = Math.max(headers.length, sheet.getLastColumn() || 1);
      const existingHeaders = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
      const match = headers.length === existingHeaders.length &&
                    headers.every((h, i) => h === existingHeaders[i]);
      if (!match) {
        sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
        sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold').setBackground('#f0f0f0');
        if (lastCol > headers.length) {
          // Clear any extra header cells
          sheet.getRange(1, headers.length + 1, 1, lastCol - headers.length).clearContent();
        }
        console.log('Updated headers for sheet:', sheetName);
      }
    }
  }
  return sheet;
}

function findRowByRemoteId(sheet, remoteId) {
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === remoteId) return i + 1;
  }
  return -1;
}

// -------- Amount parsing --------
function parseAmount(amount) {
  if (typeof amount === 'number') {
    console.log('Amount numeric:', amount);
    return amount;
  }

  if (typeof amount === 'string') {
    console.log('Parsing currency string:', amount);
    let cleanAmount = amount
      .replace(/R\$|US\$|\$|€|£|¥|₹|₽/g, '')
      .replace(/[\s\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]/g, '')
      .trim();

    // Brazilian format if last comma is after last dot
    if (cleanAmount.includes(',') && cleanAmount.lastIndexOf(',') > cleanAmount.lastIndexOf('.')) {
      cleanAmount = cleanAmount.replace(/\./g, '').replace(',', '.');
    } else {
      // US/other: remove thousands commas, keep last dot as decimal
      const parts = cleanAmount.split('.');
      if (parts.length > 1) {
        const decimal = parts.pop();
        const integer = parts.join('').replace(/,/g, '');
        cleanAmount = integer + '.' + decimal;
      } else {
        cleanAmount = cleanAmount.replace(/,/g, '');
      }
    }

    const parsed = parseFloat(cleanAmount);
    if (isNaN(parsed)) {
      console.error('Could not parse amount:', amount, '->', cleanAmount);
      return 0;
    }
    return parsed;
  }

  console.error('Amount not number/string:', amount);
  return 0;
}

// -------- Date normalization helpers (fix for filtering) --------
function normalizeDateToYmd(value) {
  // Returns 'YYYY-MM-DD' or '' if not parseable
  const tz = Session.getScriptTimeZone() || 'UTC';

  // Date object
  if (Object.prototype.toString.call(value) === '[object Date]' && !isNaN(value)) {
    return Utilities.formatDate(value, tz, 'yyyy-MM-dd');
  }

  // Sheets/Excel serial number
  if (typeof value === 'number') {
    const ms = (value - 25569) * 86400000; // days to ms since 1899-12-30
    const d = new Date(ms);
    if (!isNaN(d)) return Utilities.formatDate(d, tz, 'yyyy-MM-dd');
  }

  // String cases
  if (typeof value === 'string') {
    const s = value.trim();

    // ISO-like
    const iso = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (iso) return `${iso[1]}-${iso[2]}-${iso[3]}`;

    // dd/mm/yyyy or dd-mm-yyyy
    const br = s.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
    if (br) {
      const dd = br[1].padStart(2, '0');
      const mm = br[2].padStart(2, '0');
      const yyyy = br[3];
      return `${yyyy}-${mm}-${dd}`;
    }

    // Fallback parse
    const d = new Date(s);
    if (!isNaN(d)) return Utilities.formatDate(d, tz, 'yyyy-MM-dd');
  }

  return '';
}

function ymdToEpoch(ymd) {
  if (!ymd) return NaN;
  const [y, m, d] = ymd.split('-').map(Number);
  const dt = new Date(y, m - 1, d); // midnight in script TZ
  return dt.getTime();
}

// -------- GET /getTransactions with fixed filtering & stable same-day order --------
function getTransactions(e) {
  try {
    const spreadsheet = getOrCreateSpreadsheet();
    const sheet = spreadsheet.getSheetByName('Transactions');

    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        message: 'Transactions sheet not found',
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const values = sheet.getDataRange().getValues();
    if (values.length <= 1) {
      return ContentService.createTextOutput(JSON.stringify({
        success: true,
        message: 'No transactions found',
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const headers = values[0];
    const dataRows = values.slice(1);

    // Build objects and normalize date for each, track row index as tie-breaker
    const transactions = dataRows.map((row, idx) => {
      const obj = {};
      headers.forEach((h, i) => obj[h] = row[i] == null ? '' : row[i]);
      const ymd = normalizeDateToYmd(obj.dateISO);
      obj._dateYMD = ymd;
      obj._dateEpoch = ymdToEpoch(ymd);
      obj._rowIndex = idx + 2; // actual sheet row (header is row 1)
      return obj;
    });

    // Read filters
    const limitParam = parseInt(e.parameter.limit, 10);
    const limit = isNaN(limitParam) ? 300 : Math.max(0, limitParam);

    const startDateParam = e.parameter.startDate || null; // 'YYYY-MM-DD'
    const endDateParam   = e.parameter.endDate   || null;
    const categoryName   = e.parameter.categoryName || null;
    const paymentMethod  = e.parameter.paymentMethod || null;
    const transactionType= e.parameter.transactionType || null;

    const startEpoch = startDateParam ? ymdToEpoch(startDateParam) : NaN;
    const endEpoch   = endDateParam   ? ymdToEpoch(endDateParam)   : NaN;

    let filtered = transactions;

    // Date filter (inclusive)
    if (startDateParam || endDateParam) {
      const before = filtered.length;
      filtered = filtered.filter(t => {
        if (isNaN(t._dateEpoch)) return false;
        let ok = true;
        if (!isNaN(startEpoch)) ok = ok && (t._dateEpoch >= startEpoch);
        if (!isNaN(endEpoch))   ok = ok && (t._dateEpoch <= endEpoch + 86399999); // include whole end day
        return ok;
      });
      console.log(`Date filtering: ${before} -> ${filtered.length} using ${startDateParam || '-∞'} to ${endDateParam || '+∞'}`);
    }

    if (categoryName) {
      const needle = categoryName.toLowerCase();
      filtered = filtered.filter(t => String(t.categoryName || '').toLowerCase().includes(needle));
    }

    if (paymentMethod) {
      const needle = paymentMethod.toLowerCase();
      filtered = filtered.filter(t => String(t.paymentMethod || '').toLowerCase().includes(needle));
    }

    if (transactionType) {
      const needle = transactionType.toLowerCase();
      filtered = filtered.filter(t => String(t.transactionType || '').toLowerCase() === needle);
    }

    // Sort newest first by date; for same date, newest insertion (higher row) first
    filtered.sort((a, b) => {
      const ae = isNaN(a._dateEpoch) ? -Infinity : a._dateEpoch;
      const be = isNaN(b._dateEpoch) ? -Infinity : b._dateEpoch;
      if (be !== ae) return be - ae;             // primary: date
      return b._rowIndex - a._rowIndex;          // secondary: row index (newer rows first)
    });

    const result = limit > 0 ? filtered.slice(0, limit) : filtered;

    // Strip internal fields
    const cleaned = result.map(({ _dateYMD, _dateEpoch, _rowIndex, ...rest }) => rest);

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: `Retrieved ${cleaned.length} transactions`,
      total: transactions.length,
      filtered: cleaned.length,
      data: cleaned
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    console.error('Error getting transactions:', error);
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      message: 'Error retrieving transactions: ' + error.message,
      data: []
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// -------- FIXED: GET /getCategories with consistent headers --------
function getCategories(e) {
  try {
    const limitParam = parseInt(e.parameter.limit, 10);
    const limit = isNaN(limitParam) ? 0 : Math.max(0, limitParam);

    const ss = getOrCreateSpreadsheet();
    const sheet = ss.getSheetByName('Categories');
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({
        success: true,
        message: 'Categories sheet not found',
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const values = sheet.getDataRange().getValues();
    if (values.length <= 1) {
      return ContentService.createTextOutput(JSON.stringify({
        success: true,
        message: 'No categories found',
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const headers = values[0];
    const rows = values.slice(1);

    // FIXED: Use consistent camelCase headers that match Swift expectations
    const objs = rows.map((row, idx) => {
      const obj = {
        remoteID: row[0] || '',
        name: row[1] || '',
        emoji: row[2] || '',
        sortIndex: parseInt(row[3]) || 0,
        isIncome: Boolean(row[4]),
        timestamp: row[5] || ''
      };
      obj._rowIndex = idx + 2;
      return obj;
    });

    // newest first = higher row index first
    objs.sort((a, b) => b._rowIndex - a._rowIndex);

    const trimmed = (limit > 0 ? objs.slice(0, limit) : objs)
      .map(({ _rowIndex, ...rest }) => rest);

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: `Retrieved ${trimmed.length} categories`,
      total: objs.length,
      data: trimmed
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    console.error('Error getting categories:', error);
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      message: 'Error retrieving categories: ' + error.message,
      data: []
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// -------- FIXED: GET /getPaymentMethods with consistent headers --------
function getPaymentMethods(e) {
  try {
    const limitParam = parseInt(e.parameter.limit, 10);
    const limit = isNaN(limitParam) ? 0 : Math.max(0, limitParam);

    const ss = getOrCreateSpreadsheet();
    const sheet = ss.getSheetByName('PaymentMethods');
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({
        success: true,
        message: 'PaymentMethods sheet not found',
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const values = sheet.getDataRange().getValues();
    if (values.length <= 1) {
      return ContentService.createTextOutput(JSON.stringify({
        success: true,
        message: 'No payment methods found',
        data: []
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const headers = values[0];
    const rows = values.slice(1);

    // FIXED: Use consistent camelCase headers that match Swift expectations
    const objs = rows.map((row, idx) => {
      const obj = {
        remoteID: row[0] || '',
        name: row[1] || '',
        emoji: row[2] || '',
        sortIndex: parseInt(row[3]) || 0,
        timestamp: row[4] || ''
      };
      obj._rowIndex = idx + 2;
      return obj;
    });

    objs.sort((a, b) => b._rowIndex - a._rowIndex);

    const trimmed = (limit > 0 ? objs.slice(0, limit) : objs)
      .map(({ _rowIndex, ...rest }) => rest);

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: `Retrieved ${trimmed.length} payment methods`,
      total: objs.length,
      data: trimmed
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    console.error('Error getting payment methods:', error);
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      message: 'Error retrieving payment methods: ' + error.message,
      data: []
    })).setMimeType(ContentService.MimeType.JSON);
  }
}
