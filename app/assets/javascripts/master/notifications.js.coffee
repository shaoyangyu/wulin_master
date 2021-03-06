notifications = []
duration = 3 # Seconds

container = ->
  $('#notificationContainer')  

isContainerCreated = ->
  container().length > 0

buildNotificationHtml = (message) ->
  component = $('<div/>')
  component.addClass('notification')
  component.html(message)
  component.css('display', 'none')
  component
  
initializeContainer = ->
  if isContainerCreated()
    return true
  containerElement = $('<div/>')
  containerElement.attr('id', 'notificationContainer')
  $('body').append(containerElement)
  
discardNotification = (notification) ->
  removeNotification = ->
    notification.remove() 
  notification.slideUp('fast', -> removeNotification())
    
window.displayNewNotification = (message, always) ->
  initializeContainer()
  notification = buildNotificationHtml(message)
  container().append(notification)
  notification.slideDown('fast')
  notification.bind('click', -> discardNotification(notification))
  timedDiscard = ->
    discardNotification(notification)
  setTimeout(timedDiscard, duration*1000) unless always
  true