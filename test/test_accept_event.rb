# frozen_string_literal: true

require_relative 'lib/common'

# Test accept event binding
class TestAcceptEvent < TestInteractive
  def test_accept_event_with_become_default_key
    # AC1: Binding accept:become(...) executes the command when an item is accepted
    # Test with default Enter key triggering accept
    tmux.send_keys "seq 100 | fzf --bind 'accept:become(echo accepted: {})'",:Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    tmux.send_keys '99'
    tmux.until { |lines| assert_equal 1, lines.match_count }
    tmux.send_keys :Enter
    tmux.until { |lines| assert_includes lines, 'accepted: 99' }
  end

  def test_accept_event_with_become_remapped_key
    # AC2: If accept keybinding is remapped (via user options), accept:... still triggers correctly
    # Remap ctrl-x to accept instead of enter, and verify accept event still fires
    tmux.send_keys "seq 100 | fzf --bind 'ctrl-x:accept' --bind 'accept:become(echo remapped: {})'",:Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    tmux.send_keys '50'
    tmux.until { |lines| assert_equal 1, lines.match_count }
    # Try Enter first - should not trigger accept event since it's remapped
    tmux.send_keys :Enter
    sleep 0.5
    # Now send ctrl-x which should trigger accept
    tmux.send_keys 'C-x'
    tmux.until { |lines| assert_includes lines, 'remapped: 50' }
  end

  def test_accept_event_with_multiple_accept_keys
    # AC2: Verify accept event works when multiple keys are bound to accept action
    output = '/tmp/fzf-test-accept-event'
    FileUtils.rm_f(output)
    tmux.send_keys "seq 100 | fzf --bind 'ctrl-y:accept,tab:accept' --bind 'accept:execute-silent(echo {} >> #{output})+accept'", :Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    
    # Test ctrl-y triggers accept event
    tmux.send_keys '10'
    tmux.until { |lines| assert_equal 2, lines.match_count }
    tmux.send_keys 'C-y'
    sleep 0.3
    
    tmux.send_keys "seq 100 | fzf --bind 'ctrl-y:accept,tab:accept' --bind 'accept:execute-silent(echo {} >> #{output})+accept'", :Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    
    # Test tab triggers accept event
    tmux.send_keys '20'
    tmux.until { |lines| assert_equal 2, lines.match_count }
    tmux.send_keys :Tab
    sleep 0.3
    
    wait do
      assert_path_exists output
      lines = File.readlines(output, chomp: true)
      assert_equal 2, lines.length
      assert_includes lines, '10'
      assert_includes lines, '20'
    end
  ensure
    FileUtils.rm_f(output)
  end

  def test_accept_event_coexists_with_key_bindings
    # AC3: Existing bindings like enter:... remain functional
    output = '/tmp/fzf-test-accept-coexist'
    FileUtils.rm_f(output)
    
    # Bind both enter:execute and accept:execute to verify they can coexist
    tmux.send_keys "seq 100 | fzf --bind 'enter:execute-silent(echo enter >> #{output})' --bind 'accept:execute-silent(echo accept >> #{output})+accept'", :Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    tmux.send_keys '42'
    tmux.until { |lines| assert_equal 1, lines.match_count }
    tmux.send_keys :Enter
    sleep 0.3
    
    wait do
      assert_path_exists output
      lines = File.readlines(output, chomp: true)
      # Both enter and accept events should fire
      assert_includes lines, 'enter'
      assert_includes lines, 'accept'
    end
  ensure
    FileUtils.rm_f(output)
  end

  def test_accept_event_with_accept_non_empty
    # Test that accept event fires with accept-non-empty action variant
    tmux.send_keys "seq 100 | fzf --bind 'enter:accept-non-empty' --bind 'accept:become(echo non-empty: {})'",:Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    tmux.send_keys '77'
    tmux.until { |lines| assert_equal 1, lines.match_count }
    tmux.send_keys :Enter
    tmux.until { |lines| assert_includes lines, 'non-empty: 77' }
  end

  def test_accept_event_with_accept_or_print_query
    # Test that accept event fires with accept-or-print-query action variant
    tmux.send_keys "seq 100 | fzf --bind 'enter:accept-or-print-query' --bind 'accept:become(echo query-or-item: {})'",:Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    tmux.send_keys 'nomatch'
    tmux.until { |lines| assert_equal 0, lines.match_count }
    tmux.send_keys :Enter
    tmux.until { |lines| assert_includes lines, 'query-or-item: nomatch' }
  end

  def test_accept_event_tmux_example
    # Reproduce the example from the ticket description
    # Create a mock tmux session list
    output = '/tmp/fzf-test-tmux-sessions'
    FileUtils.rm_f(output)
    writelines(['session1', 'session2', 'session3'])
    
    tmux.send_keys "cat #{tempname} | fzf --prompt='Session> ' --bind='accept:execute-silent(echo switch-to: {} >> #{output})+accept'", :Enter
    tmux.until { |lines| assert_equal 3, lines.match_count }
    tmux.send_keys '2'
    tmux.until { |lines| assert_equal 1, lines.match_count }
    tmux.send_keys :Enter
    
    wait do
      assert_path_exists output
      assert_equal ['switch-to: session2'], File.readlines(output, chomp: true)
    end
  ensure
    FileUtils.rm_f(output)
  end

  def test_accept_event_does_not_fire_on_abort
    # Verify that accept event does NOT fire when user aborts (Ctrl-C/Esc)
    output = '/tmp/fzf-test-no-accept-on-abort'
    FileUtils.rm_f(output)
    
    tmux.send_keys "seq 100 | fzf --bind 'accept:execute-silent(echo accepted >> #{output})'", :Enter
    tmux.until { |lines| assert_equal 100, lines.match_count }
    tmux.send_keys '55'
    tmux.until { |lines| assert_equal 1, lines.match_count }
    
    # Abort with Ctrl-C
    tmux.send_keys 'C-c'
    sleep 0.3
    
    # File should not exist since accept event should not have fired
    refute File.exist?(output), 'accept event should not fire on abort'
  ensure
    FileUtils.rm_f(output)
  end
end
