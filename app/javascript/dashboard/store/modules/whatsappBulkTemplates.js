import WhatsappBulkTemplatesAPI from 'dashboard/api/whatsappBulkTemplates';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isSyncing: false,
  },
};

export const getters = {
  getAll: _state => _state.records,
  getApproved: _state => _state.records.filter(t => t.status === 'approved'),
  getUIFlags: _state => _state.uiFlags,
};

export const actions = {
  async get({ commit }) {
    commit('SET_UI_FLAGS', { isFetching: true });
    try {
      const { data } = await WhatsappBulkTemplatesAPI.get();
      commit('SET_RECORDS', data.payload || data);
    } finally {
      commit('SET_UI_FLAGS', { isFetching: false });
    }
  },

  async create({ commit }, template) {
    commit('SET_UI_FLAGS', { isCreating: true });
    try {
      const { data } = await WhatsappBulkTemplatesAPI.create({ template });
      commit('ADD_RECORD', data.payload || data);
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isCreating: false });
    }
  },

  async update({ commit }, { id, template }) {
    commit('SET_UI_FLAGS', { isUpdating: true });
    try {
      const { data } = await WhatsappBulkTemplatesAPI.update(id, { template });
      commit('UPDATE_RECORD', data.payload || data);
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isUpdating: false });
    }
  },

  async delete({ commit }, id) {
    commit('SET_UI_FLAGS', { isDeleting: true });
    try {
      await WhatsappBulkTemplatesAPI.delete(id);
      commit('DELETE_RECORD', id);
    } finally {
      commit('SET_UI_FLAGS', { isDeleting: false });
    }
  },

  async syncFromProvider({ commit }) {
    commit('SET_UI_FLAGS', { isSyncing: true });
    try {
      const { data } = await WhatsappBulkTemplatesAPI.syncFromProvider();
      commit('SET_RECORDS', data.templates || data);
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isSyncing: false });
    }
  },
};

export const mutations = {
  SET_UI_FLAGS(_state, flags) {
    _state.uiFlags = { ..._state.uiFlags, ...flags };
  },
  SET_RECORDS(_state, records) {
    _state.records = records;
  },
  ADD_RECORD(_state, record) {
    _state.records.unshift(record);
  },
  UPDATE_RECORD(_state, record) {
    _state.records = _state.records.map(item =>
      item.id === record.id ? record : item
    );
  },
  DELETE_RECORD(_state, id) {
    _state.records = _state.records.filter(item => item.id !== id);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
