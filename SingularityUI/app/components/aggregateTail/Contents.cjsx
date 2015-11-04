LogLine = require './LogLine'
Loader = require './Loader'

Contents = React.createClass

  # ============================================================================
  # Lifecycle Methods                                                          |
  # ============================================================================

  getInitialState: ->
    @state =
      contentsHeight: Math.max(document.documentElement.clientHeight, window.innerHeight || 0) - 180
      isLoading: false
      loadingText: ''
      linesToRender: []

  componentWillMount: ->
    $(window).on 'resize orientationChange', @handleResize

  componentDidMount: ->
    @scrollNode = @refs.scrollContainer.getDOMNode()
    @currentOffset = parseInt @props.offset

  componentDidUpdate: (prevProps, prevState) ->
    # Scroll to the appropriate place
    if @state.linesToRender.length > 0 and prevState.linesToRender.length is 0
      if !@props.offset
        @scrollToBottom()
      else
        @setScrollHeight(20)
        
    else if @tailingPoll
      @scrollToBottom()
    else if prevProps.contentScroll isnt @props.contentScroll
      @setScrollHeight(@props.contentScroll)

    # Start tailing automatically if we can't scroll
    if 0 < $('.line').length * 20 <= @state.contentsHeight and !@tailingPoll
      @startTailingPoll()

    # Update our loglines components only if needed
    if prevProps.logLines.length isnt @props.logLines.length
      @setState
        linesToRender: @renderLines()

  componentWillUnmount: ->
    $(window).off 'resize orientationChange', @handleResize

  # ============================================================================
  # Event Handlers                                                             |
  # ============================================================================

  handleResize: ->
    @setState
      contentsHeight: Math.max(document.documentElement.clientHeight, window.innerHeight || 0) - 180

  handleScroll: (node) ->
    # Are we at the bottom?
    if $(node).scrollTop() + $(node).innerHeight() >= node.scrollHeight
      @startTailingPoll(node)
    # Or the top?
    else if $(node).scrollTop() is 0
      @props.fetchPrevious()
    else
      @stopTailingPoll()

  handleHighlight: (e) ->
    @currentOffset = parseInt $(e.target).attr 'data-offset'
    @setState
      linesToRender: @renderLines()

  startTailingPoll: ->
    # Make sure there isn't one already running
    @stopTailingPoll()

    @setState
      isLoading: true
      loadingText: 'Tailing...'
    @props.fetchNext()
    @tailingPoll = setInterval @props.fetchNext, 1000

  stopTailingPoll: ->
    @setState
      isLoading: false
      loadingText: ''
    clearInterval @tailingPoll
    @tailingPoll = null

  # ============================================================================
  # Rendering                                                                  |
  # ============================================================================

  renderError: ->
    if @props.ajaxError.present
      <div className="lines-wrapper">
          <div className="empty-table-message">
              <p>{@props.ajaxError.message}</p>
          </div>
      </div>

  renderLines: ->
    if @props.logLines
      @props.logLines.map((l, i) =>
        <LogLine
          content={l.data}
          offset={l.offset}
          key={i}
          index={i}
          highlighted={l.offset is @currentOffset}
          highlight={@handleHighlight} />
      )

  render: ->
    <div className="contents-container">
      <div className="tail-contents">
        {@renderError()}
        <Infinite
          ref="scrollContainer"
          className="infinite"
          containerHeight={@state.contentsHeight}
          preloadAdditionalHeight={@state.contentsHeight * 2.5}
          elementHeight={20}
          handleScroll={_.throttle @handleScroll, 200}>
          {@state.linesToRender}
        </Infinite>
      </div>
      <Loader isVisable={@state.isLoading} text={@state.loadingText} />
    </div>

  # ============================================================================
  # Utility Methods                                                            |
  # ============================================================================

  setScrollHeight: (height) ->
    $(@scrollNode).scrollTop(height);

  scrollToTop: ->
    @stopTailingPoll()
    @setState
      isLoading: true
    @props.fetchFromStart().done =>
      @setScrollHeight(0)
      @setState
        isLoading: false

  scrollToBottom: ->
    @setScrollHeight(@scrollNode.scrollHeight)

module.exports = Contents