BioPieces
=========

Installation
------------

`gem install biopieces`

Add the following alias to your `~/.bashrc` file:

`alias bp="irb -r biopieces --noinspect"`


Getting started
---------------

A test script:

    #!/usr/bin/env ruby
    
    require 'biopieces'
    
    p = BioPieces::Pipeline.new
    
    p.add(:read_fasta, input: "input.fna")
    p.add(:grab, select: "ATC$", keys: :SEQ)
    p.add(:write_fasta, output: "output.fna")
    p.run(progress: true)

Or in irb using the alias bp:

    $ bp
    irb(main):001:0> p = BP.new
    => BioPieces::Pipeline.new
    irb(main):002:0> p.add(:read_fasta, input: "input.fna")
    => BioPieces::Pipeline.new.add(:read_fasta, input: "input.fna")
    irb(main):003:0> p.add(:grab, select: "ATC$", keys: :SEQ)
    => BioPieces::Pipeline.new.add(:read_fasta, input: "input.fna").add(:grab, select: "ATC$", keys: :SEQ)
    irb(main):004:0> p.add(:write_fasta, output: "output.fna")
    => BioPieces::Pipeline.new.add(:read_fasta, input: "input.fna").add(:grab, select: "ATC$", keys: :SEQ).add(:write_fasta, output: "output.fna")
    irb(main):005:0> p.run(progress: true)
    => BioPieces::Pipeline.new.add(:read_fasta, input: "input.fna").add(:grab, select: "ATC$", keys: :SEQ).add(:write_fasta, output: "output.fna").run(progress: true)
    irb(main):006:0>

Or chaining commands directoy:

    $ bp
    irb(main):001:0> BioPieces::Pipeline.new.add(:read_fasta, input: "input.fna").add(:grab, select: "ATC$", keys: :SEQ).add(:write_fasta, output: "output.fna").run
    => BioPieces::Pipeline.new.add(:read_fasta, input: "input.fna").add(:grab, select: "ATC$", keys: SEQ).add(:write_fasta, output: "output.fna").run
    irb(main):002:0>

Log and History
---------------

All BioPieces events are logged to `~/.biopieces_log`.

BioPieces history is saved to `~/.biopieces_history`.


Features
--------

Progress:

`BP.new.add(:read_fasta, input: "input.fna").add(:dump).run(progress: true)`

E-mail notification:

`BP.new.add(:read_fasta, input: "input.fna").add(:dump).run(email: mail@maasha.dk, subject: "Script done!")`

