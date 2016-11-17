import _ from 'lodash';
import definitions from './definitions.yml';
import reduxUtil from '../../services/redux-util';

const prefix = reduxUtil.fromFilenameToPrefix(__filename);

function selectKernel(payload) {
  return {type: prefix + 'SELECT_CONNECTION', payload};
}

function addChange(payload) {
  return {type: prefix + 'ADD_CHANGE', payload};
}

function addKernel() {
  return {type: prefix + 'ADD_CONNECTION'};
}

function removeKernel(payload) {
  return {type: prefix + 'REMOVE_CONNECTION', payload};
}

function connect(id) {
  return function (dispatch, getState) {
    const state = getState(),
      proposedConnectionConfig = _.find(state.manageConnections.list, {id});

    if (proposedConnectionConfig) {
      const definition = _.find(definitions.types, {name: proposedConnectionConfig.type}),
        allowedOptions = ['id', 'type'].concat(Object.keys(definition.knownConfigurationOptions));

      if (definition) {
        const connectionConfig = _.defaults(_.pick(proposedConnectionConfig, allowedOptions), definition.defaults);

        return dispatch({type: prefix + 'CONNECT', payload: connectionConfig});
      }
    }
  };
}

function disconnect(id) {
  return function (dispatch) {
    return dispatch({type: prefix + 'DISCONNECT', payload: id});
  };
}

export default {
  addChange,
  addKernel,
  connect,
  disconnect,
  removeKernel,
  selectKernel
};
