import React, { useEffect, useReducer, useCallback } from 'react';
import { supabase } from '../supabaseClient';
import { fetchAdminInfoByEmail } from '../services/api';

// Minimal API calls colocated to avoid large diffs in services
async function listWardens() {
	const { data, error } = await supabase.from('wardens').select('*').order('email');
	if (error) throw new Error(error.message || 'Failed to list wardens');
	return data || [];
}

async function addWarden(email, hostels) {
	const { error } = await supabase.from('wardens').insert([{ email: email.toLowerCase(), hostels: hostels || [] }]);
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
	form: { email: '', hostels: '' },
	isSuperAdmin: false,
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
	const { rows, loading, error, success, form, isSuperAdmin } = state;

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
			dispatch({ type: 'SET', payload: { rows: data } });
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
			const hostels = form.hostels.split(',').map(h => h.trim()).filter(Boolean);
			await addWarden(form.email, hostels);
			dispatch({ type: 'SET', payload: { success: 'Warden added', form: { email: '', hostels: '' } } });
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
			const hostels = (row?.hostels_input || '').split(',').map(h => h.trim()).filter(Boolean);
			await updateWarden(email, hostels);
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

	return (
		<div style={{ padding: 24 }}>
			<h2>Super Admin: Warden Management</h2>
			{!isSuperAdmin && <div style={{ color: 'red', marginBottom: 12 }}>Only super admin can access this page.</div>}
			{error && <div style={{ color: 'red', marginBottom: 12 }}>{error}</div>}
			{success && <div style={{ color: 'green', marginBottom: 12 }}>{success}</div>}
			<div style={{ marginBottom: 16, display: 'flex', gap: 8, alignItems: 'center' }}>
				<input
					placeholder="Warden email"
					value={form.email}
					onChange={(e) => dispatch({ type: 'SET_FORM_FIELD', field: 'email', value: e.target.value })}
					style={{ padding: 8, minWidth: 280 }}
				/>
				<input
					placeholder="Hostels (comma separated)"
					value={form.hostels}
					onChange={(e) => dispatch({ type: 'SET_FORM_FIELD', field: 'hostels', value: e.target.value })}
					style={{ padding: 8, minWidth: 280 }}
				/>
				<button onClick={handleAdd} disabled={loading || !isSuperAdmin}>Add Warden</button>
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
					{rows.map(row => (
						<tr key={row.email}>
							<td style={{ padding: 8 }}>{row.email}</td>
							<td style={{ padding: 8 }}>
								<input
									defaultValue={(row.hostels || []).join(', ')}
									onChange={(e) => row.hostels_input = e.target.value}
									style={{ width: '100%', padding: 6 }}
								/>
							</td>
							<td style={{ padding: 8, display: 'flex', gap: 8 }}>
								<button onClick={() => handleUpdate(row.email)} disabled={loading || !isSuperAdmin}>Save</button>
								<button onClick={() => handleDelete(row.email)} disabled={loading || !isSuperAdmin} style={{ color: '#b71c1c' }}>Delete</button>
							</td>
						</tr>
					))}
				</tbody>
			</table>
		</div>
	);
};

export default WardenManagement;
