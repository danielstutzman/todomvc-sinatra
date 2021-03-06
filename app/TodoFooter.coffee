React = require 'react'

type = React.PropTypes

TodoFooter = React.createClass

  displayName: 'TodoFooter'

  propTypes:
    count:          type.number.isRequired
    completedCount: type.number.isRequired
    nowShowing:     type.string.isRequired
    doCommand:      type.func.isRequired

  handleClearCompleted: ->
    @props.doCommand 'delete_completed_todos'

  render: ->

    { a, button, div, li, span, strong, ul } = React.DOM

    selectedIfShowing = (option) =>
      if @props.nowShowing == option then 'selected'

    div
      id: 'footer'
      span
        id: 'todo-count'
        strong {},
          @props.count
        " #{if @props.count == 1 then 'item' else 'items'} left"
      ul
        id: 'filters'
        li {},
          a
            href: '#/'
            className: selectedIfShowing('all')
            'All'
        ' '
        li {},
          a
            href: '#/active'
            className: selectedIfShowing('active')
            'Active'
        ' '
        li {},
          a
            href: '#/completed'
            className: selectedIfShowing('completed')
            'Completed'
      if @props.completedCount > 0
        button
          id: 'clear-completed'
          onClick: @handleClearCompleted
          "Clear completed (#{@props.completedCount})"

module.exports = TodoFooter
