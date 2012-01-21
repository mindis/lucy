# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
package Lucy::Build::Binding::Index::Posting;

sub bind_all {
    my $class = shift;
    $class->bind_matchposting;
    $class->bind_richposting;
    $class->bind_scoreposting;
}

sub bind_matchposting {
    my $synopsis = <<'END_SYNOPSIS';
    # MatchPosting is used indirectly, by specifying in FieldType subclass.
    package MySchema::Category;
    use base qw( Lucy::Plan::FullTextType );
    sub posting {
        my $self = shift;
        return Lucy::Index::Posting::MatchPosting->new(@_);
    }
END_SYNOPSIS

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel            => "Lucy",
        class_name        => "Lucy::Index::Posting::MatchPosting",
        bind_constructors => ["new"],
        bind_methods      => [qw( Get_Freq )],
        #    make_pod => {
        #        synopsis => $synopsis,
        #    }
    );
    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_richposting {
    my $synopsis = <<'END_SYNOPSIS';
    # RichPosting is used indirectly, by specifying in FieldType subclass.
    package MySchema::Category;
    use base qw( Lucy::Plan::FullTextType );
    sub posting {
        my $self = shift;
        return Lucy::Index::Posting::RichPosting->new(@_);
    }
END_SYNOPSIS

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel            => "Lucy",
        class_name        => "Lucy::Index::Posting::RichPosting",
        bind_constructors => ["new"],
        #    make_pod => {
        #        synopsis => $synopsis,
        #    }
    );
    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_scoreposting {
    my $xs_code = <<'END_XS_CODE';
MODULE = Lucy   PACKAGE = Lucy::Index::Posting::ScorePosting

SV*
get_prox(self)
    lucy_ScorePosting *self;
CODE:
{
    AV *out_av            = newAV();
    uint32_t *positions  = Lucy_ScorePost_Get_Prox(self);
    uint32_t i, max;

    for (i = 0, max = Lucy_ScorePost_Get_Freq(self); i < max; i++) {
        SV *pos_sv = newSVuv(positions[i]);
        av_push(out_av, pos_sv);
    }

    RETVAL = newRV_noinc((SV*)out_av);
}
OUTPUT: RETVAL
END_XS_CODE

    my $synopsis = <<'END_SYNOPSIS';
    # ScorePosting is used indirectly, by specifying in FieldType subclass.
    package MySchema::Category;
    use base qw( Lucy::Plan::FullTextType );
    # (It's the default, so you don't need to spec it.)
    # sub posting {
    #     my $self = shift;
    #     return Lucy::Index::Posting::ScorePosting->new(@_);
    # }
END_SYNOPSIS

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel            => "Lucy",
        class_name        => "Lucy::Index::Posting::ScorePosting",
        xs_code           => $xs_code,
        bind_constructors => ["new"],
        #    make_pod => {
        #        synopsis => $synopsis,
        #    }
    );
    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

1;
