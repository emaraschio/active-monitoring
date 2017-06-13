import { connect } from 'react-redux'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { addEmptySymptom, editSymptom, removeSymptom } from '../actions/symptoms'
import { campaignUpdate } from '../actions/campaign'
import Button from 'react-md/lib/Buttons/Button'
import List from 'react-md/lib/Lists/List'
import ListItem from 'react-md/lib/Lists/ListItem'
import EditableTitleLabel from './EditableTitleLabel'
import FontIcon from 'react-md/lib/FontIcons'
import SelectField from 'react-md/lib/SelectFields'
import TextField from './TextField'

class SymptomStepComponent extends Component {
  render() {
    return (
      <div>
        <div className='md-grid'>
          <div className='md-cell md-cell--12'>
            <h3>Define the symptoms</h3>
            <p>
              The symptoms will be used to evaluate positive cases of the disease and send alerts to the persons responsible. Later you will be asked to upload audio explaining how to evaluate this symptoms.
            </p>
          </div>
        </div>
        <div className='md-grid'>
          <SelectField
            id='forwarding-condition'
            menuItems={[{value: 'any', label: 'Forward call if any symptom is positive'}, {value: 'all', label: 'Forward call if all symptoms are positive'}]}
            position={SelectField.Positions.BELOW}
            className='md-cell md-cell--8  md-cell--bottom'
            defaultValue='any'
            value={this.props.forwardingCondition}
            onChange={(val) => this.props.onEditForwarding('forwardingCondition', val)}
          />
          <TextField
            id='forwarding-number'
            label='Forward number'
            className='md-cell md-cell--4'
            defaultValue={this.props.forwardingNumber}
            onSubmit={(val) => this.props.onEditForwarding('forwardingNumber', val)}
          />
        </div>
        <div className='md-grid'>
          <List className='md-cell md-cell--12'>
            {this.props.symptoms.map((symptom, i) =>
              <ListItem
                key={i}
                rightIcon={<FontIcon onClick={() => this.props.onRemove(i)}>remove_circle</FontIcon>}
                primaryText={<EditableTitleLabel
                  title={symptom}
                  emptyText={'Insert symptom'}
                  readOnly={false}
                  onSubmit={(title) => this.props.onEdit(title, i)}
                  hideEditingIcon />}
              />)}
          </List>
          <Button flat label='Add symptom' onClick={this.props.onAdd}>add</Button>
        </div>
      </div>
    )
  }
}

SymptomStepComponent.propTypes = {
  symptoms: PropTypes.arrayOf(PropTypes.string),
  onRemove: PropTypes.func,
  onAdd: PropTypes.func,
  onEdit: PropTypes.func,
  forwardingNumber: PropTypes.string,
  forwardingCondition: PropTypes.string,
  onEditForwarding: PropTypes.func
}

const mapStateToProps = (state) => {
  return {
    symptoms: state.campaign.data.symptoms || [],
    forwardingNumber: state.campaign.data.forwardingNumber,
    forwardingCondition: state.campaign.data.forwardingCondition
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onAdd: () => dispatch(addEmptySymptom()),
    onEdit: (symptom, index) => dispatch(editSymptom(symptom, index)),
    onRemove: (index) => dispatch(removeSymptom(index)),
    onEditForwarding: (key, value) => dispatch(campaignUpdate({[key]: value}))
  }
}

const SymptomStep = connect(
  mapStateToProps,
  mapDispatchToProps
)(SymptomStepComponent)

export default SymptomStep