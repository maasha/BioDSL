BioPieces
=========

Installation
------------

`gem install biopieces`

Add the following alias to your `~/.bashrc` file:

`alias bp="ruby -r biopieces"`
`alias ibp="irb -r biopieces --noinspect"`


Getting started
---------------

A test script:

    #!/usr/bin/env ruby
    
    require 'biopieces'
    
    p = BP.new
    p.read_fasta(input: "input.fna")
    p.grab(select: "ATC$", keys: :SEQ)
    p.write_fasta(output: "output.fna")
    p.run(progress: true)

Or using an interactive shell using the alias ibp:

    $ ibp
    irb(main):001:0> p = BP.new
    => BioPieces::Pipeline.new
    irb(main):002:0> p.read_fasta(input: "input.fna")
    => BioPieces::Pipeline.new.read_fasta(input: "input.fna")
    irb(main):003:0> p.grab(select: "ATC$", keys: :SEQ)
    => BioPieces::Pipeline.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ)
    irb(main):004:0> p.write_fasta(output: "output.fna")
    => BioPieces::Pipeline.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna")
    irb(main):005:0> p.run(progress: true)
    => BioPieces::Pipeline.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    irb(main):006:0>


Or chaining commands directly:

    $ ibp
    irb(main):001:0> BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    => BioPieces::Pipeline.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)
    irb(main):002:0>

Or run on the command line with the alias bp:

    $ bp -e 'BP.new.read_fasta(input: "input.fna").grab(select: "ATC$", keys: :SEQ).write_fasta(output: "output.fna").run(progress: true)'

Log and History
---------------

All BioPieces events are logged to `~/.biopieces_log`.

BioPieces history is saved to `~/.biopieces_history`.


Features
--------

Progress:

`BP.new.read_fasta(input: "input.fna").dump.run(progress: true)`

E-mail notification:

`BP.new.read_fasta(input: "input.fna").dump.run(email: mail@maasha.dk, subject: "Script done!")`


Contributing
------------

Fork it
Create your feature branch (git checkout -b my-new-feature)
Commit your changes (git commit -am 'Add some feature')
Push to the branch (git push origin my-new-feature)
Create new Pull Request
