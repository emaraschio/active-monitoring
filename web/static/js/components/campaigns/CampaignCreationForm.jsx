// @flow
import { connect } from 'react-redux'
import React, { Component } from 'react'
import { ScrollToLink, animatedScrollTo } from '../ScrollToLink'
import PositionFixer from '../PositionFixer'
import SymptomStep from './SymptomStep'
import LanguageStep from './LanguageStep'
import UploadAudioStep from './UploadAudioStep'
import ChannelStep from './ChannelStep'
import EducationalInformationStep from './EducationalInformationStep'
import MonitoringSettingsStep from './MonitoringSettingsStep'
import { campaignLaunch } from '../../actions/campaign'
import { activeCampaignUsing } from '../../reducers/campaigns'
import List from 'react-md/lib/Lists/List'
import ListItem from 'react-md/lib/Lists/ListItem'
import FontIcon from 'react-md/lib/FontIcons'
import Subheader from 'react-md/lib/Subheaders'
import Button from 'react-md/lib/Buttons'
import values from 'lodash/values'
import flatten from 'lodash/flatten'
import { audioEntries, audiosInUse } from '../../selectors/campaign'
import type { Campaign } from '../../types'

type Props = {
  campaign: Campaign,
  launchCampaign: (campaignId: number) => void,
  neededAudios: number,
  activeCampaignUsing: (channel: string) => Campaign,
  uploadedAudios: number
}

type State = {
  attemptLaunch: boolean
}

class CampaignCreationFormComponent extends Component {
  props: Props
  state: State

  constructor(props) {
    super(props)
    this.state = {
      attemptLaunch: false
    }
  }

  completedSymptomStep() {
    return this.props.campaign.symptoms.filter((symptom) => symptom[1].length > 0).length > 0 && this.props.campaign.forwardingNumber != null
  }

  completedAudioStep() {
    return (this.props.uploadedAudios > 1) && (this.props.uploadedAudios == this.props.neededAudios)
  }

  completedEducationalInformationStep() {
    return this.props.campaign.additionalInformation != null
  }

  completedMonitoringSettingsStep() {
    return this.props.campaign.timezone != null && this.props.campaign.monitorDuration != null
  }

  completedLanguageStep() {
    return this.props.campaign.langs.filter((lang) => lang.length > 0).length > 0
  }

  completedChannelSelectionStep() {
    return this.props.campaign.channel != null && !this.props.activeCampaignUsing(this.props.campaign.channel)
  }

  launch() {
    this.setState({attemptLaunch: true})
  }

  render() {
    const steps = [this.completedSymptomStep(), this.completedAudioStep(), this.completedEducationalInformationStep(), this.completedMonitoringSettingsStep(), this.completedLanguageStep(), this.completedChannelSelectionStep()]
    const numberOfCompletedSteps = steps.filter(item => item == true).length
    const percentage = `${(100 / steps.length * numberOfCompletedSteps).toFixed(0)}%`

    let launchComponent = null
    if (numberOfCompletedSteps == steps.length) {
      launchComponent = (
        <Button floating secondary
          tooltipLabel='Launch campaign'
          tooltipPosition='top'
          className='launch-campaign'
          // TODO: disable Launch button between click and response
          onClick={() => this.props.launchCampaign(this.props.campaign.id)}>play_arrow</Button>
      )
    }

    return (
      <div className='md-grid white'>
        <div className='md-cell md-cell--12-tablet md-cell--4-desktop md-cell--tablet-hidden '>
          <PositionFixer offset={60}>
            <div className='md-paper md-paper--1 rounded-corners'>
              <List className='wizard'>
                <Subheader primaryText={<p>Complete the following tasks to get your Campaign ready.</p>}>
                  <h2>Progress <span className='pull-right'>{percentage}</span></h2>
                  <div className='progress'>
                    <div className='determinate' style={{ width: percentage }} />
                  </div>
                  {launchComponent}
                </Subheader>
                <ListItem onClick={(e) => animatedScrollTo(e, 'symptoms')} leftIcon={<FontIcon className='step-icon'>{this.completedSymptomStep() ? 'check_circle' : 'healing'}</FontIcon>} rightIcon={<FontIcon>keyboard_arrow_right</FontIcon>} primaryText='Define the symptoms' className={this.completedSymptomStep() ? 'green-text' : ''} />
                <ListItem onClick={(e) => animatedScrollTo(e, 'information')} leftIcon={<FontIcon className='step-icon'>{this.completedEducationalInformationStep() ? 'check_circle' : 'info'}</FontIcon>} rightIcon={<FontIcon>keyboard_arrow_right</FontIcon>} primaryText='Educational information' className={this.completedEducationalInformationStep() ? 'green-text' : ''} />
                <ListItem onClick={(e) => animatedScrollTo(e, 'monitoring')} leftIcon={this.completedMonitoringSettingsStep() ? <FontIcon className='step-icon'>check_circle</FontIcon> : <img src='/images/campaign-black.svg' width='24' />} rightIcon={<FontIcon>keyboard_arrow_right</FontIcon>} primaryText='Set up monitoring settings' className={this.completedMonitoringSettingsStep() ? 'green-text' : ''} />
                <ListItem onClick={(e) => animatedScrollTo(e, 'languages')} leftIcon={<FontIcon className='step-icon'>{this.completedLanguageStep() ? 'check_circle' : 'translate'}</FontIcon>} rightIcon={<FontIcon>keyboard_arrow_right</FontIcon>} primaryText='Select languages' className={this.completedLanguageStep() ? 'green-text' : ''} />
                <ListItem onClick={(e) => animatedScrollTo(e, 'audios')} leftIcon={<FontIcon className='step-icon'>{this.completedAudioStep() ? 'check_circle' : 'volume_up'}</FontIcon>} rightIcon={<FontIcon>keyboard_arrow_right</FontIcon>} primaryText='Upload audio files' className={this.completedAudioStep() ? 'green-text' : ''} />
                <ListItem onClick={(e) => animatedScrollTo(e, 'channel')} leftIcon={<FontIcon className='step-icon'>{this.completedChannelSelectionStep() ? 'check_circle' : 'phone'}</FontIcon>} rightIcon={<FontIcon>keyboard_arrow_right</FontIcon>} primaryText='Select a channel' className={this.completedChannelSelectionStep() ? 'green-text' : ''} />
              </List>
            </div>
          </PositionFixer>
        </div>
        <div className='md-cell md-cell--12-tablet md-cell--7-desktop md-cell--1-desktop-offset wizard-content'>
          <SymptomStep>
            <ScrollToLink target='information'>NEXT: Educational information</ScrollToLink>
          </SymptomStep>
          <EducationalInformationStep>
            <ScrollToLink target='monitoring'>NEXT: Set up Monitoring Settings</ScrollToLink>
          </EducationalInformationStep>
          <MonitoringSettingsStep>
            <ScrollToLink target='languages'>NEXT: Select Languages</ScrollToLink>
          </MonitoringSettingsStep>
          <LanguageStep>
            <ScrollToLink target='audios'>NEXT: Upload audio files</ScrollToLink>
          </LanguageStep>
          <UploadAudioStep>
            <ScrollToLink target='channel'>NEXT: Select a channel</ScrollToLink>
          </UploadAudioStep>
          <ChannelStep />
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state) => {
  let activeCampaignUsingChannelIfHaveCampaigns = (campaigns) => {
    if (campaigns && campaigns.items) {
      return activeCampaignUsing(campaigns)
    }
    return () => null
  }

  return {
    campaign: state.campaign.data,
    neededAudios: flatten(values(audioEntries(state.campaign.data))).length + 1,
    uploadedAudios: audiosInUse(state.campaign.data).length,
    activeCampaignUsing: activeCampaignUsingChannelIfHaveCampaigns(state.campaigns),
    attemptLaunch: state.attemptLaunch
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    launchCampaign: (id) => dispatch(campaignLaunch(id))
  }
}

const CampaignCreationForm = connect(
  mapStateToProps,
  mapDispatchToProps
)(CampaignCreationFormComponent)

export default CampaignCreationForm
