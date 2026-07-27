import WhatsappBulkCampaignsAPI from 'dashboard/api/whatsappBulkCampaigns';

export const state = {
  records: [],
  recipients: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getAll: _state => _state.records,
  getRecipients: _state => _state.recipients,
  getUIFlags: _state => _state.uiFlags,
};

export const actions = {
  async get({ commit }) {
    commit('SET_UI_FLAGS', { isFetching: true });
    try {
      const { data } = await WhatsappBulkCampaignsAPI.get();
      commit('SET_RECORDS', data);
    } finally {
      commit('SET_UI_FLAGS', { isFetching: false });
    }
  },

  async create({ commit }, campaign) {
    commit('SET_UI_FLAGS', { isCreating: true });
    try {
      const { data } = await WhatsappBulkCampaignsAPI.create({ campaign });
      commit('ADD_RECORD', data);
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isCreating: false });
    }
  },

  async update({ commit }, { id, campaign }) {
    commit('SET_UI_FLAGS', { isUpdating: true });
    try {
      const { data } = await WhatsappBulkCampaignsAPI.update(id, { campaign });
      commit('UPDATE_RECORD', data);
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isUpdating: false });
    }
  },

  async delete({ commit }, id) {
    commit('SET_UI_FLAGS', { isDeleting: true });
    try {
      await WhatsappBulkCampaignsAPI.delete(id);
      commit('DELETE_RECORD', id);
    } finally {
      commit('SET_UI_FLAGS', { isDeleting: false });
    }
  },

  async send({ commit }, id) {
    commit('SET_UI_FLAGS', { isSending: true });
    try {
      const { data } = await WhatsappBulkCampaignsAPI.send(id);
      commit('UPDATE_RECORD', data);
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isSending: false });
    }
  },

  async pause({ commit }, id) {
    commit('SET_UI_FLAGS', { isUpdating: true });
    try {
      await WhatsappBulkCampaignsAPI.pause(id);
    } finally {
      commit('SET_UI_FLAGS', { isUpdating: false });
    }
  },

  async resume({ commit }, id) {
    commit('SET_UI_FLAGS', { isUpdating: true });
    try {
      await WhatsappBulkCampaignsAPI.resume(id);
    } finally {
      commit('SET_UI_FLAGS', { isUpdating: false });
    }
  },

  async cancel({ commit }, id) {
    commit('SET_UI_FLAGS', { isUpdating: true });
    try {
      await WhatsappBulkCampaignsAPI.cancel(id);
    } finally {
      commit('SET_UI_FLAGS', { isUpdating: false });
    }
  },

  async fetchRecipients({ commit }, campaignId) {
    commit('SET_UI_FLAGS', { isFetching: true });
    try {
      const { data } = await WhatsappBulkCampaignsAPI.recipients(campaignId);
      commit('SET_RECIPIENTS', data);
    } finally {
      commit('SET_UI_FLAGS', { isFetching: false });
    }
  },

  async importRecipients({ commit }, { id, file }) {
    commit('SET_UI_FLAGS', { isImporting: true });
    try {
      const { data } = await WhatsappBulkCampaignsAPI.importRecipients(id, file);
      commit('UPDATE_RECORD', data);
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isImporting: false });
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
  SET_RECIPIENTS(_state, recipients) {
    _state.recipients = recipients;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
