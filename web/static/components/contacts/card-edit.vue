<template>
  <div class="col-md-12 card-block">
    <div class="post" v-if="item">
    <div class="pull-right">
      <button type="button" class="btn btn-primary pull-right browse" v-on:click="browse">BROWSE</button>
      <br />
       <div class="upload-btn btn btn-default archive" style="margin-top: 10px; height: 34px;width: 130px;font-weight:normal;">
        <file-upload
          title="UPLOAD FILE"
          name="attachment"
          :post-action="'/api/v2/card/' + card.id + '/attachments'"
          :headers="uploadHeaders"
          :events="uploadEvents"
          ref="attachment">
        </file-upload>
      </div>
      <br />
      <button type="button" class="btn btn-default archive " v-on:click="openDueDatePicker">DUE DATE</button>
      <br />
      <button type="button" v-show="item.status === 0" class="btn btn-default archive " v-on:click="archiveCard">ARCHIVE</button>
      <button type="button" v-show="item.status === 1" class="btn btn-default archive " v-on:click="unarchiveCard">UNARCHIVE</button>
      <br />
      <br />
      <div class="text-center" style="margin-top:10px;color:grey;">
        <a class="show-more" v-show="!showMoreOptions" @click="showMoreOptions=true" style="text-decoration:none;">+More options</a>
      </div>
      <div v-show="showMoreOptions">
        <delete-contact :contact="contact"></delete-contact>
      </div>
    </div>
      <div style="" id="change_status">
        <span>
          <span data-placeholder="Project Name" style="color:rgb(99,99,99);font-weight:bold;font-size: 24px;">
            <i class="fa fa-rocket" style="color:#d8d8d8;"></i>
            In <board-column-select :board-id="item.board_id" :board-column-id="item.board_column_id" @input='boardColumnChange' />

            <div v-if="item.name">
              <inline-edit v-model="item.name" v-on:input="updateCard" placeholder="Card Name" style="width:500px;margin-left:25px;color:grey;"></inline-edit>
            </div>
          </span>
        </span>
        <br />
        <br />
        Contacts Involved:
        <span v-for="o_contact in cardContacts" class="o_contact">
          <a href='#' v-on:click="changeContactDisplay($event, o_contact.id)">{{o_contact.name}}</a>
          <a class="remove" @click="removeContact(o_contact.id)" v-if="cardContacts.length > 1">×</a>
        </span>

        <modal large :show.sync="openContactModal">
          <div slot="modal-header" class="modal-header">
           <button type="button" class="close" @click="openContactModal=false"><span>&times;</span></button>
           <h4 class="modal-title">What is his name?</h4>
          </div>
            <div slot="modal-body" class="modal-body">
            <input class="form-control" v-model="NewContactName" type="text" placeholder="Name of the Contact">
            </div>
            <div slot="modal-footer" class="modal-footer">
             <button type="button" class="btn btn-success" v-on:click="addContact">Add Contact</button>
            </div>
        </modal>

        <button type="button" class="btn btn-link add_o_contact" v-on:click="openContactModal = true" >
          <i class="fa fa-fw fa-plus"></i>Add ...
        </button>
        <div class="managers">
          Managed by:
          <select v-model.number="item.user_id"  v-on:change="updateCard">
            <option v-for="user in company_users" :value.number="user.id">{{user.user_name}}</option>
          </select>

        </div>
        <div class="mt-1 mb-1" :class="{ 'is-due-past': !isDueFuture, 'is-due-future': isDueFuture }" v-show="item.due_date || showDueDatePicker" >
          Due Date:
          <el-date-picker
            class="card-due-date"
            v-on:change="updateCard"
            v-model="item.due_date"
            type="datetime"
            size="mini"
            format="yyyy-MM-dd HH:mm"
            :editable="false"
            :min_date="new Date()"
            :clearable="true"
            ref="dueDatePicker"
            >
          </el-date-picker>
        </div>
        <div class="mt-1 mb-1">
          Description
          <br />
          <div class="mt-1" data-placeholder="Write a description...">
            <markdown-text-edit v-model="item.description" v-on:input="updateCard" placeholder="Write a description" ></markdown-text-edit>
          </div>
          <br />
        </div>


      </div>
      <div class="attachments">

         <h3 style="color:rgb(99,99,99);font-weight:bold;"  v-if="attachments.length > 0">
           <i class="fa fa-fw fa-paperclip" style="color:#d8d8d8;"></i>Attachments
         </h3>

         <div v-if="attachments.length > 0">
           <div v-for="attach in attachments" :class="['attach-item', attach.ext_file]">
             <div :class="['thumb', fileTypeClass(attach)]" >
               <img :src="attach.thumb_url" v-if="attach.image" />
             </div>
             <div class="info">
             <div>{{attach.file_name}}</div>
             <div>Added {{attach.inserted_at | moment('MMM DD [at] h:m A')}}</div>
             <div class="attach-action">
              <a :href="attach.attachment_url" target="_blank">
               <i class="fa fa-download" aria-hidden="true"></i>
               Download</a>
              <button class="btn btn-link" v-on:click.stop="deleteAttachment(attach.id)">
              <i class="fa fa-times" aria-hidden="true"></i>
               Delete</button>
             </div>
             </div>
           </div>
         </div>
        </div>
      <to-do
        :activities="activities"
        :companyUsers="company_users"
        :contact="contact"
        :card="card"
        :company="company"
        :timeZone="time_zone"
        v-on:taskAddOrUpdate="taskAddOrUpdate"
        v-on:taskDelete="taskDelete"
      >

        <comment_form slot="comment-form"
          :contact="contact"
          :card="card"
          :user_image="user_image"
          v-on:eventAddOrUpdate="eventAddOrUpdate"

         />
        <timeline_events
          slot="timeline-events"
          :events="events"
          v-on:eventDelete="eventDelete"
          />
      </to-do>

    </div>
  </div>

</template>

<script>
  import InlineEdit from '../inline-common-edit.vue';
  import ToDo from './to-do-edit.vue';
  import CommentForm from './comment-form.vue';
  import TimelineEvents from './timeline-events.vue';
  import MarkdownTextEdit from '../markdown-textedit.vue';
  import DeleteContact from './delete.vue';
  import BoardColumnSelect from '../shared/board-column-select-modal.vue';

  export default {
    props: [
      'socket',
      'contact', 'time_zone', 'current_user_id',
      'card', 'company',
      'cards',
      'company_users',
      'organization',
      'user_image'
    ],
    data(){
      return {
        uploadEvents: {
          add(file, component) {
            component.active = true;
          },
          progress(file, component) {
            let msg = 'Uploading ' + Math.ceil(file.progress) + '%';
            this.$notification.$emit('alert', {'msg': msg});
          },
          after(file, component) {
            this.$notification.$emit('alert', {'msg': 'Finished!'});
          },
          before(file, component) {
            this.$notification.$emit('alert', {'msg': 'Start upload'});
          }
        },
        attachment: {},
        attachments: [],
        openContactModal: false,
        allowUpdate: true,
        item: this.card,
        items: this.cards,
        contacts: this.cardContacts,
        boardColumns: [],
        board: {},
        cardChannel: null,
        activities: [],
        events: [],
        cardContacts: [],
        showMoreOptions: false,
        showDueDatePicker: false

      };
    },
    computed: {
      isDueFuture(){
        return this.item.due_date > new Date();
      },
      uploadHeaders(){
        return { Authorization: 'Bearer ' + Vue.currentUser.token   };
      }
    },
    methods: {
      openDueDatePicker() {
        let vm = this;
        vm.showDueDatePicker = true;
        vm.$refs.dueDatePicker.handleClose = function() {
          vm.showDueDatePicker = false;
          this.pickerVisible = false;
        };
        vm.$refs.dueDatePicker.showPicker();
      },
      changeContactDisplay(event, contactId) {
        event.preventDefault();
        this.$emit('changeContactDisplay', contactId);
      },
      eventAddOrUpdate(event) {
        let itemIndex = this.$data.events.findIndex(function(item){
          return item.id === parseInt(event.id);
        });
        if (itemIndex === -1){
          this.$data.events.unshift(event);
        } else {
          this.$data.events.splice(itemIndex, 1, event);
        }
      },
      eventDelete(eventId) {
        let itemIndex = this.$data.events.findIndex(function(item){
          return item.id === parseInt(eventId);
        });
        if (itemIndex !== -1){ this.$data.events.splice(itemIndex, 1); }
      },
      taskAddOrUpdate(task) {
        let itemIndex = this.$data.activities.findIndex(function(item){
          return item.id === parseInt(task.id);
        });
        if (itemIndex === -1){
          this.$data.activities.push(task);
        } else {
          this.$data.activities.splice(itemIndex, 1, task);
        }
      },
      taskDelete(taskId) {
        let itemIndex = this.$data.activities.findIndex(function(item){
          return item.id === parseInt(taskId);
        });
        if (itemIndex !== -1){ this.$data.activities.splice(itemIndex, 1); }
      },
      fileTypeClass(attach) {
        const klasses = {
          '.pdf': 'fa fa-file-pdf-o'
        };

        let cssClass = '';
        if (!attach.image) {
          cssClass = 'file ' + (klasses[attach.ext_file] || 'fa fa-file-o');
        }
        return cssClass;
      },
      deleteAttachment(attachId) {
        let url = '/api/v2/card/'+this.item.id+'/attachments/' + attachId;
        this.$http.delete(url, {  });
      },
      browse(){
        this.leaveChannel();
        this.$emit('browse');
      },
      addContact(){
        let url = '/api/v2/contact';
        let data = {
          name: this.NewContactName,
          userId: this.card.user_id
        };
        if (this.company) {
          data['company_id'] = this.company.id;
        }
        if (this.organization) {
          data['organization_id'] = this.organization.id;
        }
        this.$http.post(url, { contact: data }).then(resp => {
          let urlOpp = '/api/v2/card/'+ this.card.id;
          let contactIds = [];
          this.cardContacts.push(resp.data.data);
          this.item.contact_ids.push(resp.data.data.id);
          this.$http.put(urlOpp,{ card: { contactIds: this.item.contact_ids  } });
        });

        this.NewContactName = '';
        this.openContactModal = false;
      },
      removeContact(contactId) {
        if(confirm('Are you sure?')) {
          this.item.contact_ids.splice(this.item.contact_ids.indexOf(contactId), 1);

          let url = '/api/v2/card/' + this.item.id;
          this.$http.put(url, {card: { contactIds: this.item.contact_ids}}).then(resp => {
            if(resp.data.errors && resp.data.errors.contact_ids) {
              alert(resp.data.errors.contact_ids);
            } else {
              var index = -1;
              for(var i=0; i < this.cardContacts.length; i++) {
                if(this.cardContacts[i].id === contactId) {
                  index = i;
                  break;
                }
              }
              if(index !== -1) {
                this.cardContacts.splice(index, 1);
              }
            }
          }, resp => {
            if(resp.data.errors.contact_ids) {
              alert(resp.data.errors.contact_ids);
            }
          });
        }
      },
      archiveCard() {
        let url = '/api/v2/card/' + this.item.id;
        this.$http.put(url, { card: { status: '1'} });
      },
      unarchiveCard() {
        let url = '/api/v2/card/' + this.item.id;
        this.$http.put(url, { card: { status: '0'} });
      },

      refreshCard(payload){
        if (payload.activities) {
          this.$data.activities = payload.activities;
        }
        if (payload.board) {
          this.$data.board = payload.board;
          this.$data.boardColumns = payload.board_columns;
        }

        if (payload.events) {
          this.$data.events = payload.events;
        }

        if (payload.card) {
          this.$data.item = payload.card;
        }
        if (payload.card_contacts) {
          this.$data.cardContacts = payload.card_contacts;
        }

        if (payload.attachments) {
          this.$data.attachments = payload.attachments;
        }
        this.allowUpdate = true;
      },

      subscribe() {

        this.cardChannel.on('card:updateddd', payload => {
          this.allowUpdate = false;
          if (payload.card) {
            this.$data.item = payload.card;
            this.$data.cardContacts = payload.card_contacts;

            let itemIndex = this.cards.findIndex(function(item){
              return item.id === parseInt(payload.card.id);
            });

            this.$data.items.splice(itemIndex, 1, payload.card);
          }
          if (payload.board) {
            this.$data.board = payload.board;
            this.$data.boardColumns = payload.board_columns;
          }

          if (payload.card.status.toString() === '1') {
            this.$emit('browse');
          }
          this.allowUpdate = true;
        });

        this.cardChannel.on('card:added_attachment', payload => {
          if (payload.card) {
            this.$data.attachments.unshift(payload.attachment);
          }
        });

        this.cardChannel.on('card:deleted_attachment', payload => {
          if (payload.card) {

            let itemIndex = this.attachments.findIndex(function(item){
              return item.id === parseInt(payload.attachment_id);
            });

            this.$data.attachments.splice(itemIndex, 1);
          }
        });

        this.cardChannel.on('activity:created', payload => {
          this.taskAddOrUpdate(payload.activity);
        });

        this.cardChannel.on('activity:deleted', payload => {
          this.taskDelete(payload.activity_id);
        });

        this.cardChannel.on('activity:updated', payload => {
          this.taskAddOrUpdate(payload.activity);
        });

        this.cardChannel.on('timeline_event:created', payload => {
          if (payload.event.event_name === 'comment') {
            this.eventAddOrUpdate(payload.event);
          }
        });

        this.cardChannel.on('timeline_event:updated', payload => {
          if (payload.event.event_name === 'comment') {
            this.eventAddOrUpdate(payload.event);
          }
        });

        this.cardChannel.on('timeline_event:deleted', payload => {
          this.eventDelete(payload.id);
        });
      },
      leaveChannel() {
        if (this.$data.cardChannel) {
          this.$data.cardChannel.leave();
        }
      },
      initChannel(){
        let channelTopic = 'cards:' + this.card.id;
        if (this.card.id) {
          this.$http.get('/api/v2/card/' + this.card.id).then(resp => {
            this.refreshCard(resp.data);
          });
        }
        this.cardChannel = this.socket.channels.find(function(item){
          return channelTopic === item.topic;
        });

        if (this.cardChannel) {
          this.subscribe();
        } else {
          this.cardChannel = this.socket.channel(channelTopic, {});
          this.subscribe();
          this.cardChannel.join()
                .receive('ok', resp => { })
                .receive('error', resp => {  });
        }
      },

      clearCard() {
        this.allowUpdate = false;
        this.$data.item = null;
        this.leaveChannel();
      },
      setCard(opp) {
        this.allowUpdate = false;
        this.$data.item = opp;
        this.initChannel();
      }
    },
    watch: {
      card() {
        this.allowUpdate = false;
        this.$data.item = this.card;

        if (this.card){
          this.initChannel();
        } else { this.leaveChannel(); }
      }
    },
    components: {
      'inline-edit': InlineEdit,
      'to-do': ToDo,
      'comment_form': CommentForm,
      'timeline_events': TimelineEvents,
      'markdown-text-edit': MarkdownTextEdit,
      'v-select': vSelect.VueSelect,
      'modal': VueStrap.modal,
      'file-upload': FileUpload,
      'delete-contact': DeleteContact,
      'board-column-select': BoardColumnSelect,
      'el-date-picker': ElementUi.DatePicker
    },

    mounted() {
      this.attachment = this.$refs.attachment.$data;
      this.initChannel();
    }

  };
</script>
<style lang="sass">
  .is-due-past {
    .card-due-date {
      .el-input__inner {
        background-color: #f3d0d0;
      }
    }
  }
  .card-due-date {
    width:140px !important;
    .el-input__inner {
      background-color: #eaeaea;
    }
  }
  .attachments {
  margin-bottom: 20px;
  .attach-item {
  position: relative;
  border-bottom: 0.1em solid #e4e4e4;


  .thumb {
  height: 75px;
  width: 75px;
  img {
  max-height: 75px;
  max-width: 75px;
  }
  &.file {
  font-size: 55px;
  &:before {
  position: absolute;
  top: 8px;
  left: 8px;
  }
  }
  }
  .info {
  position:absolute;
  left: 105px;
  top: 0px;
  }

  }
  }

  .show-more, .hide-more,
  .show-more:hover, .hide-more:hover {
    color: #333;
    cursor: pointer;
    text-decoration: underline;
    margin-top: 10px;
    display: block;
  }
</style>
