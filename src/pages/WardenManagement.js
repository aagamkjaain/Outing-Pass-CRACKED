import React, { useEffect, useReducer, useCallback } from 'react';
import { supabase } from '../supabaseClient';
import { fetchAdminInfoByEmail } from '../services/api';
import * as XLSX from 'xlsx';
// Minimal API calls colocated to avoid large diffs in services
async function listWardens() {
    const { data, error } = await supabase.from('wardens').select('id,email,hostels').order('email');
	if (error) throw new Error(error.message || 'Failed to list wardens');
	return data || [];
}
async function addWarden(email, hostels) {
    // Upsert to avoid duplicate key violation
    const { error } = await supabase.from('wardens').upsert(
        [{ email: email.toLowerCase(), hostels: hostels || [] }],
        { onConflict: 'email' }
    );
	if (error) throw new Error(error.message || 'Failed to add warden');
}
async function updateWarden(email, hostels) {
	const { error } = await supabase.from('wardens').update({ hostels }).eq('email', email.toLowerCase());
	if (error) throw new Error(error.message || 'Failed to update warden');
}
async function deleteWarden(email) {
	const { error } = await supabase.from('wardens').delete().eq('email', email.toLowerCase());
	if (error) throw new Error(error.message || 'Failed to delete warden');
}
const initialState = {
    rows: [],
    loading: false,
    error: '',
    success: '',
    form: { email: '', selectedHostel: '' },
    isSuperAdmin: false,
    hostelOptions: [],
    search: '',
    upload: { inProgress: false, total: 0, processed: 0, eta: '', message: '' },
};
function reducer(state, action) {
	switch (action.type) {
		case 'SET':
			return { ...state, ...action.payload };
		case 'SET_FIELD':
			return { ...state, [action.field]: action.value };
		case 'SET_FORM_FIELD':
			return { ...state, form: { ...state.form, [action.field]: action.value } };
		default:
			return state;
	}
}
const WardenManagement = () => {
	const [state, dispatch] = useReducer(reducer, initialState);
    const { rows, loading, error, success, form, isSuperAdmin, hostelOptions } = state;
	const load = useCallback(async () => {
		dispatch({ type: 'SET', payload: { loading: true, error: '', success: '' } });
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) throw new Error('Not authenticated');
			const adminInfo = await fetchAdminInfoByEmail(user.email);
			const superAdmin = adminInfo?.role === 'superadmin';
			dispatch({ type: 'SET', payload: { isSuperAdmin: superAdmin } });
			if (!superAdmin) throw new Error('Only super admin can manage wardens');
        const data = await listWardens();
        // Derive hostel options from existing wardens to avoid heavy distinct scans
        const optionsSet = new Set();
        (data || []).forEach(w => (w.hostels || []).forEach(h => { if (h) optionsSet.add(String(h).trim()); }));
        const options = Array.from(optionsSet).sort((a,b) => a.localeCompare(b));
        dispatch({ type: 'SET', payload: { rows: data, hostelOptions: options } });
		} catch (e) {
			dispatch({ type: 'SET', payload: { error: e.message || 'Failed to load wardens' } });
		} finally {
			dispatch({ type: 'SET', payload: { loading: false } });
		}
	}, []);
	useEffect(() => { load(); }, [load]);
    const handleAdd = async () => {
		try {
			dispatch({ type: 'SET', payload: { loading: true, error: '', success: '' } });
            const email = (form.email || '').trim().toLowerCase();
            if (!email || !email.endsWith('@srmist.edu.in')) {
                throw new Error('Enter a valid @srmist.edu.in email');
            }
            const hostel = (form.selectedHostel || '').trim();
            if (!hostel) { throw new Error('Select a hostel'); }
            await addWarden(email, [hostel]);
            dispatch({ type: 'SET', payload: { success: 'Warden added', form: { email: '', selectedHostel: '' } } });
			await load();
		} catch (e) {
			dispatch({ type: 'SET', payload: { error: e.message || 'Failed to add' } });
		} finally {
			dispatch({ type: 'SET', payload: { loading: false } });
		}
	};
    const handleUpdate = async (email) => {
		try {
			dispatch({ type: 'SET', payload: { loading: true, error: '', success: '' } });
			const row = rows.find(r => r.email === email);
            const hostel = row?.hostel_selected || (row?.hostels && row.hostels[0]) || '';
            if (!hostel) { throw new Error('Select a hostel'); }
            await updateWarden(email, [hostel]);
			dispatch({ type: 'SET', payload: { success: 'Warden updated' } });
			await load();
		} catch (e) {
			dispatch({ type: 'SET', payload: { error: e.message || 'Failed to update' } });
		} finally {
			dispatch({ type: 'SET', payload: { loading: false } });
		}
	};
	const handleDelete = async (email) => {
		if (!window.confirm(`Delete warden ${email}?`)) return;
		try {
			dispatch({ type: 'SET', payload: { loading: true, error: '', success: '' } });
			await deleteWarden(email);
			dispatch({ type: 'SET', payload: { success: 'Warden deleted' } });
			await load();
		} catch (e) {
			dispatch({ type: 'SET', payload: { error: e.message || 'Failed to delete' } });
		} finally {
			dispatch({ type: 'SET', payload: { loading: false } });
		}
	};
    const handleDeleteAll = async () => {
        if (!window.confirm('Delete ALL wardens? This cannot be undone.')) return;
        const text = window.prompt('Type DELETE ALL to confirm');
        if (!text || text.trim().toLowerCase() !== 'delete all') {
            dispatch({ type: 'SET', payload: { error: 'Bulk delete cancelled. Confirmation text did not match.' } });
            return;
        }
        try {
            dispatch({ type: 'SET', payload: { loading: true, error: '', success: '' } });
            const { error } = await supabase.from('wardens').delete().neq('email', '');
            if (error) throw error;
            dispatch({ type: 'SET', payload: { success: 'All wardens deleted' } });
            await load();
        } catch (e) {
            dispatch({ type: 'SET', payload: { error: e.message || 'Failed to delete all' } });
        } finally {
            dispatch({ type: 'SET', payload: { loading: false } });
        }
    };
    const handleDownloadTemplate = () => {
        const templateData = [
            { 'Warden Email': 'warden1@srmist.edu.in', 'Hostel': 'mullai' },
            { 'Warden Email': 'warden2@srmist.edu.in', 'Hostel': 'mbblock' }
        ];
        const wb = XLSX.utils.book_new();
        const ws = XLSX.utils.json_to_sheet(templateData);
        ws['!cols'] = [{ wch: 28 }, { wch: 20 }];
        XLSX.utils.book_append_sheet(wb, ws, 'Wardens');
        // Add allowed hostels sheet for reference
        const hostelsSheet = XLSX.utils.aoa_to_sheet([[ 'Allowed Hostels' ], ...((hostelOptions || []).map(h => [h]))]);
        XLSX.utils.book_append_sheet(wb, hostelsSheet, 'Hostels');
        XLSX.writeFile(wb, 'warden_template.xlsx');
    };
    const handleBulkUpload = async (e) => {
        const file = e.target.files?.[0];
        if (!file) return;
        try {
            dispatch({ type: 'SET', payload: { loading: true, error: '', success: '', upload: { inProgress: true, total: 0, processed: 0, eta: '', message: 'Parsing file...' } } });
            const data = await file.arrayBuffer();
            const wb = XLSX.read(data);
            const ws = wb.Sheets[wb.SheetNames[0]];
            const rows = XLSX.utils.sheet_to_json(ws);
            const payload = [];
            const invalid = [];
            for (const row of rows) {
                const rawEmail = String(row['Warden Email'] || '').trim().toLowerCase();
                const hostelRaw = String(row['Hostel'] || '').trim();
                if (!rawEmail || !rawEmail.endsWith('@srmist.edu.in') || !hostelRaw) continue;
                // Validate hostel against options (case-insensitive)
                const match = (hostelOptions || []).find(h => h.toLowerCase() === hostelRaw.toLowerCase());
                if (!match) { invalid.push(hostelRaw); continue; }
                payload.push({ email: rawEmail, hostels: [match] });
            }
            if (invalid.length > 0) {
                throw new Error(`Unknown hostels in file: ${Array.from(new Set(invalid)).join(', ')}`);
            }
            if (payload.length === 0) throw new Error('No valid rows found in file');
            const total = payload.length;
            const chunkSize = 100;
            const startedAt = Date.now();
            let processed = 0;
            for (let i = 0; i < payload.length; i += chunkSize) {
                const chunk = payload.slice(i, i + chunkSize);
                const { error } = await supabase.from('wardens').upsert(chunk, { onConflict: 'email' });
                if (error) throw error;
                processed += chunk.length;
                const elapsedSec = Math.max(1, Math.floor((Date.now() - startedAt) / 1000));
                const rate = processed / elapsedSec; // rows per sec
                const remaining = Math.max(0, total - processed);
                const etaSec = rate > 0 ? Math.ceil(remaining / rate) : 0;
                const eta = `${Math.floor(etaSec / 60)}m ${etaSec % 60}s`;
                dispatch({ type: 'SET', payload: { upload: { inProgress: true, total, processed, eta, message: `Uploading ${processed}/${total}...` } } });
            }
            dispatch({ type: 'SET', payload: { success: `Uploaded ${total} wardens successfully.`, upload: { inProgress: false, total, processed: total, eta: '0s', message: 'Completed.' } } });
            await load();
        } catch (err) {
            dispatch({ type: 'SET', payload: { error: err.message || 'Bulk upload failed', upload: { inProgress: false, total: 0, processed: 0, eta: '', message: '' } } });
        } finally {
            dispatch({ type: 'SET', payload: { loading: false } });
            e.target.value = '';
        }
    };
	return (
		<div style={{ padding: 24 }}>
			<h2>Super Admin: Warden Management</h2>
			{!isSuperAdmin && <div style={{ color: 'red', marginBottom: 12 }}>Only super admin can access this page.</div>}
			{error && <div style={{ color: 'red', marginBottom: 12 }}>{error}</div>}
			{success && <div style={{ color: 'green', marginBottom: 12 }}>{success}</div>}
            <div style={{ marginBottom: 16, display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                <input
                    placeholder="Warden email (@srmist.edu.in)"
                    value={form.email}
                    onChange={(e) => dispatch({ type: 'SET_FORM_FIELD', field: 'email', value: e.target.value })}
                    style={{ padding: 8, minWidth: 280 }}
                />
                <select value={form.selectedHostel} onChange={(e) => {
                    dispatch({ type: 'SET_FORM_FIELD', field: 'selectedHostel', value: e.target.value });
                }} style={{ minWidth: 280, padding: 6 }}>
                    <option value="">Select hostel...</option>
                    {hostelOptions.map(h => (<option key={h} value={h}>{h}</option>))}
                </select>
                <button onClick={handleAdd} disabled={loading || !isSuperAdmin}>Add Warden</button>
                <button onClick={handleDownloadTemplate} type="button">Download Template</button>
                <div style={{ width: '100%' }} />
                <input type="file" accept=".xlsx,.xls,.csv" onChange={handleBulkUpload} />
                <button onClick={handleDeleteAll} type="button" className="btn-delete">Delete All</button>
            </div>
            {state.upload.inProgress && (
                <div style={{ marginBottom: 12, padding: 12, border: '1px solid #ddd', borderRadius: 6 }}>
                    <div style={{ marginBottom: 6 }}>Uploading wardens... {state.upload.processed}/{state.upload.total} • ETA: {state.upload.eta}</div>
                    <div style={{ height: 8, background: '#eee', borderRadius: 4, overflow: 'hidden' }}>
                        <div style={{ width: `${Math.min(100, Math.round((state.upload.processed / Math.max(1, state.upload.total)) * 100))}%`, height: '100%', background: '#007bff' }} />
                    </div>
                </div>
            )}
            <div style={{ marginBottom: 12 }}>
                <input
                    placeholder="Search by email..."
                    value={state.search}
                    onChange={(e) => dispatch({ type: 'SET', payload: { search: e.target.value } })}
                    style={{ padding: 8, minWidth: 320 }}
                />
            </div>
			<table style={{ width: '100%', borderCollapse: 'collapse' }}>
				<thead>
					<tr>
						<th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}>Email</th>
						<th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}>Hostels</th>
						<th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}>Actions</th>
					</tr>
				</thead>
                <tbody>
                    {(rows || []).filter(r => !state.search || r.email.toLowerCase().includes(state.search.toLowerCase())).map(row => (
						<tr key={row.email}>
							<td style={{ padding: 8 }}>{row.email}</td>
                            <td style={{ padding: 8 }}>
                                <select defaultValue={(row.hostels && row.hostels[0]) || ''} onChange={(e) => {
                                    row.hostel_selected = e.target.value;
                                }} style={{ width: '100%', padding: 6 }}>
                                    <option value="">Select hostel...</option>
                                    {hostelOptions.map(h => (<option key={h} value={h}>{h}</option>))}
                                </select>
                            </td>
							<td style={{ padding: 8, display: 'flex', gap: 8 }}>
								<button onClick={() => handleUpdate(row.email)} disabled={loading || !isSuperAdmin}>Save</button>
								<button onClick={() => handleDelete(row.email)} disabled={loading || !isSuperAdmin} className="btn-delete">Delete</button>
							</td>
						</tr>
                    ))}
				</tbody>
			</table>
		</div>
	);
};
export default WardenManagement;
